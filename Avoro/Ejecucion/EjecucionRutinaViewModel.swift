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
    @Published var ejercicios: [EjercicioEjecucionState]
    @Published var unidadSeleccionada: String
    @Published var isLoading = true
    @Published var errorMessage: String?
 
    /// [ejercicioDiaId: [numeroSerie: últimoPesoRegistrado]], siempre de una fecha anterior a hoy.
    @Published private(set) var ultimosPesos: [UUID: [Int: UltimoPesoRegistrado]] = [:]
 
    private let service = RegistroService()
    private let client = SupabaseService.shared.client
    private let kgALb = 2.20462
 
    var completados: Int { ejercicios.filter(\.completado).count }
    var total: Int { ejercicios.count }
    var rutinaTerminada: Bool { total > 0 && completados == total }
 
    init(dia: DiaConEjercicios, unidadPreferida: String) {
        self.dia = dia
        self.unidadSeleccionada = unidadPreferida
        self.ejercicios = dia.ejercicios
            .sorted { $0.orden < $1.orden }
            .map { EjercicioEjecucionState(ejercicioDia: $0) }
    }
 
    func cargarProgresoDeHoy() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
 
        do {
            for idx in ejercicios.indices {
                ejercicios[idx].registrosGuardadosHoy = []
            }
 
            let ids = ejercicios.map { $0.ejercicioDia.id }
            let registros = try await service.fetchRegistrosDeHoy(ejercicioDiaIds: ids)
 
            for registro in registros {
                if let idx = ejercicios.firstIndex(where: { $0.ejercicioDia.id == registro.ejercicioDiaId }) {
                    ejercicios[idx].registrosGuardadosHoy.append(registro)
                }
            }
            for idx in ejercicios.indices {
                let objetivo = ejercicios[idx].ejercicioDia.seriesObjetivo
                ejercicios[idx].completado = ejercicios[idx].registrosGuardadosHoy.count >= objetivo
            }
        } catch {
            errorMessage = "No se pudo cargar tu progreso de hoy."
        }
    }
 
    /// Busca, para cada ejercicio del día, el último registro guardado por serie
    /// en una fecha ANTERIOR a hoy (lo de hoy ya se maneja en cargarProgresoDeHoy).
    /// Se usa para sugerir en el placeholder el peso con el que el usuario
    /// entrenó la vez pasada.
    func cargarUltimosPesos() async {
        let ids = ejercicios.map { $0.ejercicioDia.id }
        guard !ids.isEmpty else { return }
 
        do {
            let hoy = Rutina.formatoFecha.string(from: Date())
 
            // NOTA: esto asume el cliente Supabase-swift con sintaxis fluent
            // (.from/.select/.in/.lt/.order). Si tu RegistroService ya centraliza
            // este tipo de queries, esta lógica encaja mejor ahí; la dejo aquí
            // porque el ViewModel ya tenía acceso directo a `client`.
            let registros: [RegistroEntrenamiento] = try await client
                .from("registro_entrenamiento")
                .select()
                .in("ejercicio_dia_id", values: ids.map { $0.uuidString })
                .lt("fecha", value: hoy)
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
 
    /// Valida y guarda todas las series de un ejercicio en una sola operación.
    /// Es "todo o nada": si falta un campo, no se guarda nada de ese ejercicio.
    func guardarSeries(paraEjercicioConId ejercicioDiaId: UUID) async {
        guard let index = ejercicios.firstIndex(where: { $0.id == ejercicioDiaId }) else { return }
        guard let usuarioId = client.auth.currentUser?.id else {
            errorMessage = "No se encontró tu sesión."
            return
        }
 
        let estado = ejercicios[index]
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
            await cargarProgresoDeHoy()
        } catch {
            errorMessage = "No se pudo guardar el registro. Intenta de nuevo."
        }
    }
}
