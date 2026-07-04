import Foundation
import Combine
import Supabase

@MainActor
final class RutinaListViewModel: ObservableObject {
    @Published var rutinas: [Rutina] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = RutinaService()
    private let client = SupabaseService.shared.client

    func cargarRutinas() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        guard let usuarioId = client.auth.currentUser?.id else {
            errorMessage = "No se encontró tu sesión."
            return
        }

        do {
            rutinas = try await service.fetchRutinas(usuarioId: usuarioId)
        } catch {
            errorMessage = "No se pudieron cargar tus rutinas."
        }
    }

    func eliminar(_ rutina: Rutina) async {
        do {
            try await service.eliminarRutina(id: rutina.id)
            rutinas.removeAll { $0.id == rutina.id }
        } catch {
            errorMessage = "No se pudo eliminar la rutina."
        }
    }
}
