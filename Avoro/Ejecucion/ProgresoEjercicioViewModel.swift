import Foundation
import Combine
import Supabase

/// Un punto en la gráfica de histórico de peso: la fecha y el peso máximo
/// registrado ese día (tomamos el máximo entre las series como referencia
/// del "top set" de esa sesión).
struct PuntoHistoricoPeso: Identifiable {
    let id = UUID()
    let fecha: Date
    let peso: Double
}

@MainActor
final class ProgresoEjercicioViewModel: ObservableObject {
    let ejercicioDiaId: UUID

    @Published var historial: [PuntoHistoricoPeso] = []
    @Published var isLoading = true
    @Published var errorMessage: String?

    private let client = SupabaseService.shared.client
    private let kgALb = 2.20462

    init(ejercicioDiaId: UUID) {
        self.ejercicioDiaId = ejercicioDiaId
    }

    /// Delta entre el primer y el último punto del histórico, en la unidad ya mostrada.
    var deltaHistorico: Double? {
        guard let primero = historial.first, let ultimo = historial.last, historial.count > 1 else { return nil }
        return ultimo.peso - primero.peso
    }

    func cargarHistorico(unidadDestino: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // NOTA: igual que en EjecucionRutinaViewModel.cargarUltimosPesos(),
            // esto asume la sintaxis fluent de supabase-swift. Si tienes un
            // RegistroService centralizado, esta query encaja mejor ahí.
            let registros: [RegistroEntrenamiento] = try await client
                .from("registro_entrenamiento")
                .select()
                .eq("ejercicio_dia_id", value: ejercicioDiaId.uuidString)
                .order("fecha", ascending: true)
                .execute()
                .value

            historial = agruparPorFecha(registros, unidadDestino: unidadDestino)
        } catch {
            errorMessage = "No se pudo cargar el histórico de este ejercicio."
        }
    }

    /// Convierte cada registro a la unidad seleccionada, agrupa por fecha y se
    /// queda con el peso más alto de cada sesión.
    private func agruparPorFecha(_ registros: [RegistroEntrenamiento], unidadDestino: String) -> [PuntoHistoricoPeso] {
        let convertidos = registros.map { registro in
            (fecha: registro.fecha, peso: convertir(peso: registro.peso, de: registro.unidad, a: unidadDestino))
        }

        let porFecha = Dictionary(grouping: convertidos, by: \.fecha)

        return porFecha.compactMap { fecha, valores -> PuntoHistoricoPeso? in
            guard let pesoMax = valores.map(\.peso).max(),
                  let fechaDate = Rutina.formatoFecha.date(from: fecha) else { return nil }
            return PuntoHistoricoPeso(fecha: fechaDate, peso: pesoMax)
        }
        .sorted { $0.fecha < $1.fecha }
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
}
