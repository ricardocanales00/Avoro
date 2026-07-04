import Foundation
import Combine
import SwiftUI

@MainActor
final class DiaEditorViewModel: ObservableObject {
    @Published var ejercicios: [EjercicioDiaConEjercicio]
    @Published var errorMessage: String?

    private let service = RutinaService()
    let diaRutinaId: UUID

    init(dia: DiaConEjercicios) {
        self.diaRutinaId = dia.id
        self.ejercicios = dia.ejercicios.sorted { $0.orden < $1.orden }
    }

    func agregarEjercicio(_ ejercicio: EjercicioResumen, series: Int, repeticiones: Int) async {
        let siguienteOrden = (ejercicios.map(\.orden).max() ?? 0) + 1
        do {
            let nuevo = try await service.agregarEjercicioADia(
                EjercicioDiaInsert(
                    diaRutinaId: diaRutinaId,
                    ejercicioId: ejercicio.id,
                    seriesObjetivo: series,
                    repeticionesObjetivo: repeticiones,
                    orden: siguienteOrden
                )
            )
            ejercicios.append(nuevo)
        } catch {
            errorMessage = "No se pudo agregar el ejercicio."
        }
    }

    func actualizarSeriesReps(_ item: EjercicioDiaConEjercicio, series: Int, repeticiones: Int) async {
        do {
            try await service.actualizarSeriesReps(id: item.id, series: series, repeticiones: repeticiones)
            if let index = ejercicios.firstIndex(where: { $0.id == item.id }) {
                ejercicios[index] = EjercicioDiaConEjercicio(
                    id: item.id,
                    seriesObjetivo: series,
                    repeticionesObjetivo: repeticiones,
                    orden: item.orden,
                    ejercicio: item.ejercicio
                )
            }
        } catch {
            errorMessage = "No se pudo actualizar el ejercicio."
        }
    }

    func eliminar(_ item: EjercicioDiaConEjercicio) async {
        do {
            try await service.eliminarEjercicioDia(id: item.id)
            ejercicios.removeAll { $0.id == item.id }
        } catch {
            errorMessage = "No se pudo eliminar el ejercicio."
        }
    }

    func mover(from source: IndexSet, to destination: Int) {
        ejercicios.move(fromOffsets: source, toOffset: destination)
        Task {
            for (index, item) in ejercicios.enumerated() {
                let nuevoOrden = index + 1
                if item.orden != nuevoOrden {
                    try? await service.actualizarOrdenEjercicioDia(id: item.id, orden: nuevoOrden)
                }
            }
        }
    }
}
