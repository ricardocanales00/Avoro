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

@MainActor
final class EjecucionRutinaViewModel: ObservableObject {
    let dia: DiaConEjercicios
    @Published var ejercicios: [EjercicioEjecucionState]
    @Published var unidadSeleccionada: String
    @Published var isLoading = true
    @Published var errorMessage: String?

    private let service = RegistroService()
    private let client = SupabaseService.shared.client

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
