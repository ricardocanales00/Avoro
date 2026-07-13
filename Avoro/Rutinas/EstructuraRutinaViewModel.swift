import Foundation
import Combine
import SwiftUI

@MainActor
final class EstructuraRutinaViewModel: ObservableObject {
    @Published var dias: [DiaConEjercicios] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = RutinaService()
    let rutinaId: UUID
    /// Duración del ciclo de la rutina (7, 14, etc.) — no se puede agregar
    /// más días de entrenamiento que posiciones tiene el ciclo. La base de
    /// datos también lo refuerza con un trigger, pero validar aquí primero
    /// da un mensaje inmediato en vez de esperar el error de Postgres.
    let cicloDias: Int

    init(rutina: Rutina) {
        self.rutinaId = rutina.id
        self.cicloDias = rutina.cicloDias
    }

    func cargarDias() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            dias = try await service.fetchDiasConEjercicios(rutinaId: rutinaId)
        } catch {
            errorMessage = "No se pudieron cargar los días de esta rutina."
        }
    }

    func agregarDia(nombre: String) async {
        let nombreLimpio = nombre.trimmingCharacters(in: .whitespaces)
        guard !nombreLimpio.isEmpty else { return }

        guard dias.count < cicloDias else {
            errorMessage = "Ya tienes \(dias.count) días de entrenamiento, el máximo para un ciclo de \(cicloDias) días. Aumenta la duración del ciclo desde \"Editar rutina\" si quieres agregar más."
            return
        }

        errorMessage = nil
        let siguienteOrden = (dias.map(\.orden).max() ?? 0) + 1
        do {
            let nuevo = try await service.crearDia(
                DiaRutinaInsert(rutinaId: rutinaId, nombreDia: nombreLimpio, orden: siguienteOrden)
            )
            dias.append(DiaConEjercicios(id: nuevo.id, nombreDia: nuevo.nombreDia, orden: nuevo.orden, ejercicios: []))
        } catch {
            errorMessage = "No se pudo crear el día."
        }
    }

    func eliminarDia(_ dia: DiaConEjercicios) async {
        do {
            try await service.eliminarDia(id: dia.id)
            dias.removeAll { $0.id == dia.id }
        } catch {
            errorMessage = "No se pudo eliminar el día."
        }
    }

    /// Reordena localmente y sincroniza el nuevo `orden` de cada día
    /// afectado contra la base de datos.
    func moverDias(from source: IndexSet, to destination: Int) {
        dias.move(fromOffsets: source, toOffset: destination)
        Task {
            for (index, dia) in dias.enumerated() {
                let nuevoOrden = index + 1
                if dia.orden != nuevoOrden {
                    try? await service.actualizarOrdenDia(id: dia.id, orden: nuevoOrden)
                }
            }
            await cargarDias()
        }
    }
}
