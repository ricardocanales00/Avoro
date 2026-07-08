import Foundation
import Combine
import Supabase

struct SerieCaptura: Identifiable {
    let id = UUID()
    let numeroSerie: Int
    var repeticiones: String = ""
    var peso: String = ""
}

struct EjercicioEjecucionState: Identifiable {
    let id: UUID
    let ejercicioDia: EjercicioDiaConEjercicio
    var series: [SerieCaptura]
    var completado = false
    var registrosGuardadosHoy: [RegistroEntrenamiento] = []

    init(ejercicioDia: EjercicioDiaConEjercicio) {
        self.id = ejercicioDia.id
        self.ejercicioDia = ejercicioDia
        self.series = (1...max(ejercicioDia.seriesObjetivo, 1)).map { SerieCaptura(numeroSerie: $0) }
    }
}

/// Último peso registrado por el usuario para una serie específica de un ejercicio,
/// en la unidad en la que originalmente se guardó (kg o lb).
struct UltimoPesoRegistrado {
    let peso: Double
    let unidad: String
}

@MainActor
final class EjecucionRutinaViewModel: ObservableObject {
    let dia: DiaConEjercicios
    /// La fecha con la que se van a guardar los registros de esta sesión.
    /// NO siempre es "hoy": si el usuario navegó a una fecha pasada en el
    /// calendario de Home y le dio "Iniciar rutina" ahí, esta es esa fecha
    /// pasada — el registro debe quedar guardado como si se hubiera
    /// entrenado ese día, no el día real del dispositivo.
    let fechaEntrenamiento: Date

    @Published var ejercicios: [EjercicioEjecucionState]
    @Published var unidadSeleccionada: String
    @Published var isLoading = true
    @Published var errorMessage: String?

    /// [ejercicioDiaId: [numeroSerie: últimoPesoRegistrado]], siempre de
    /// una fecha ANTERIOR a `fechaEntrenamiento` (no a "hoy real").
    @Published private(set) var ultimosPesos: [UUID: [Int: UltimoPesoRegistrado]] = [:]

    private let service = RegistroService()
    private let client = SupabaseService.shared.client
    private let kgALb = 2.20462

    private static let formatoFecha: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    var completados: Int { ejercicios.filter(\.completado).count }
    var total: Int { ejercicios.count }
    var rutinaTerminada: Bool { total > 0 && completados == total }

    /// Expuesto para que la vista pueda armar `SustituirEjercicioView` sin
    /// necesitar `import Supabase` ni tocar `client` directamente.
    var usuarioId: UUID? { client.auth.currentUser?.id }

    init(dia: DiaConEjercicios, unidadPreferida: String, fechaEntrenamiento: Date = Date()) {
        self.dia = dia
        self.unidadSeleccionada = unidadPreferida
        self.fechaEntrenamiento = fechaEntrenamiento
        self.ejercicios = dia.ejercicios
            .sorted { $0.orden < $1.orden }
            .map { EjercicioEjecucionState(ejercicioDia: $0) }
    }

    /// Carga lo ya guardado para `fechaEntrenamiento` (antes asumía "hoy").
    func cargarProgresoDeLaFecha() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            for idx in ejercicios.indices {
                ejercicios[idx].registrosGuardadosHoy = []
            }

            let ids = ejercicios.map { $0.ejercicioDia.id }
            let fechaTexto = EjecucionRutinaViewModel.formatoFecha.string(from: fechaEntrenamiento)
            let registros = try await service.fetchRegistros(ejercicioDiaIds: ids, fecha: fechaTexto)

            for registro in registros {
                if let idx = ejercicios.firstIndex(where: { $0.ejercicioDia.id == registro.ejercicioDiaId }) {
                    ejercicios[idx].registrosGuardadosHoy.append(registro)
                }
            }
            for idx in ejercicios.indices {
                let objetivo = ejercicios[idx].ejercicioDia.seriesObjetivo
                ejercicios[idx].completado = ejercicios[idx].registrosGuardadosHoy.count >= objetivo
            }

            // Si ya terminó, no tiene sentido seguir recordándole que registre
            // datos. Si no ha terminado, (re)arranca el conteo de 5 minutos —
            // esto cubre tanto la carga inicial como cada guardado exitoso,
            // ya que guardarSeries() llama a esta función al final.
            if rutinaTerminada {
                RecordatorioEntrenamientoService.cancelar()
            } else {
                RecordatorioEntrenamientoService.reprogramar()
            }
        } catch {
            errorMessage = "No se pudo cargar tu progreso de este día."
        }
    }

    /// Busca, para cada ejercicio del día, el último registro guardado por
    /// serie en una fecha ANTERIOR a `fechaEntrenamiento` (ya no a "hoy
    /// real"), para que la sugerencia tenga sentido incluso al registrar
    /// de forma retroactiva.
    func cargarUltimosPesos() async {
        let ids = ejercicios.map { $0.ejercicioDia.id }
        guard !ids.isEmpty else { return }

        do {
            let fechaCorte = EjecucionRutinaViewModel.formatoFecha.string(from: fechaEntrenamiento)

            let registros: [RegistroEntrenamiento] = try await client
                .from("registro_entrenamiento")
                .select()
                .in("ejercicio_dia_id", values: ids.map { $0.uuidString })
                .lt("fecha", value: fechaCorte)
                .order("fecha", ascending: false)
                .execute()
                .value

            ultimosPesos = agruparUltimoPesoPorSerie(registros)
        } catch {
            // No es crítico: si falla, simplemente no mostramos peso sugerido.
            ultimosPesos = [:]
        }
    }

    /// Los registros ya vienen ordenados por fecha descendente, así que el primero
    /// que encontremos para cada (ejercicioDiaId, numeroSerie) es el más reciente.
    private func agruparUltimoPesoPorSerie(_ registros: [RegistroEntrenamiento]) -> [UUID: [Int: UltimoPesoRegistrado]] {
        var resultado: [UUID: [Int: UltimoPesoRegistrado]] = [:]
        for registro in registros {
            if resultado[registro.ejercicioDiaId]?[registro.numeroSerie] == nil {
                resultado[registro.ejercicioDiaId, default: [:]][registro.numeroSerie] =
                    UltimoPesoRegistrado(peso: registro.peso, unidad: registro.unidad)
            }
        }
        return resultado
    }

    /// Peso sugerido para una serie específica, ya convertido a la unidad
    /// actualmente seleccionada por el usuario. `nil` si no hay historial.
    func pesoSugerido(paraEjercicioDiaId ejercicioDiaId: UUID, numeroSerie: Int) -> Double? {
        guard let ultimo = ultimosPesos[ejercicioDiaId]?[numeroSerie] else { return nil }
        return convertir(peso: ultimo.peso, de: ultimo.unidad, a: unidadSeleccionada)
    }

    private func convertir(peso: Double, de unidadOrigen: String, a unidadDestino: String) -> Double {
        guard unidadOrigen != unidadDestino else { return peso }
        if unidadOrigen == "kg" && unidadDestino == "lb" {
            return peso * kgALb
        } else if unidadOrigen == "lb" && unidadDestino == "kg" {
            return peso / kgALb
        }
        return peso
    }

    /// Se llama al volver del chat de sustitución. Reemplaza SOLO el
    /// ejercicio en `indice` (mismo `ejercicio_dia_id`/series/orden, pero
    /// apuntando al nuevo ejercicio del catálogo) sin tocar el resto del
    /// arreglo — así el usuario no pierde el progreso ya guardado de los
    /// demás ejercicios del día ni cambia de página.
    ///
    /// Nota (deuda técnica ya documentada): esto reinicia las series
    /// capturadas y `completado` a su estado inicial para este ejercicio,
    /// porque son datos del ejercicio anterior. El histórico de
    /// `ultimosPesos` para este `ejercicio_dia_id` sigue reflejando el
    /// ejercicio viejo hasta que se recargue — ver Sección 7.10 del doc
    /// de requisitos.
    func aplicarSustitucion(_ nuevoEjercicio: EjercicioResumen, enIndice indice: Int) {
        guard ejercicios.indices.contains(indice) else { return }

        let anterior = ejercicios[indice].ejercicioDia
        let actualizado = EjercicioDiaConEjercicio(
            id: anterior.id,
            seriesObjetivo: anterior.seriesObjetivo,
            repeticionesObjetivo: anterior.repeticionesObjetivo,
            orden: anterior.orden,
            ejercicio: nuevoEjercicio
        )
        ejercicios[indice] = EjercicioEjecucionState(ejercicioDia: actualizado)
    }

    /// Valida y guarda todas las series de un ejercicio en una sola operación.
    /// Es "todo o nada": si falta un campo, no se guarda nada de ese ejercicio.
    /// El registro se guarda con `fechaEntrenamiento`, no con la fecha real
    /// del dispositivo — así funciona el backdating desde el calendario.
    func guardarSeries(paraEjercicioConId ejercicioDiaId: UUID) async {
        guard let index = ejercicios.firstIndex(where: { $0.id == ejercicioDiaId }) else { return }
        guard let usuarioId = client.auth.currentUser?.id else {
            errorMessage = "No se encontró tu sesión."
            return
        }

        let estado = ejercicios[index]
        let fechaTexto = EjecucionRutinaViewModel.formatoFecha.string(from: fechaEntrenamiento)
        var nuevos: [NuevoRegistroEntrenamiento] = []

        for serie in estado.series {
            guard let reps = Int(serie.repeticiones), reps > 0 else {
                errorMessage = "Ingresa repeticiones válidas en todas las series de \(estado.ejercicioDia.ejercicio.nombre)."
                return
            }
            guard let peso = Double(serie.peso.replacingOccurrences(of: ",", with: ".")), peso >= 0 else {
                errorMessage = "Ingresa un peso válido en todas las series de \(estado.ejercicioDia.ejercicio.nombre)."
                return
            }
            nuevos.append(
                NuevoRegistroEntrenamiento(
                    ejercicio_dia_id: estado.ejercicioDia.id,
                    usuario_id: usuarioId,
                    fecha: fechaTexto,
                    numero_serie: serie.numeroSerie,
                    repeticiones_reales: reps,
                    peso: peso,
                    unidad: unidadSeleccionada
                )
            )
        }

        do {
            try await service.crearRegistros(nuevos)
            errorMessage = nil
            await cargarProgresoDeLaFecha()
        } catch {
            errorMessage = "No se pudo guardar el registro. Intenta de nuevo."
        }
    }
}
