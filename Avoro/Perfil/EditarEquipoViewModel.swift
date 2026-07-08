import Foundation
import Combine

@MainActor
final class EditarEquipoViewModel: ObservableObject {
    let usuarioId: UUID

    @Published var catalogo: [Equipo] = []
    @Published var seleccionados: Set<UUID> = []
    @Published var busqueda = ""
    @Published var isLoading = true
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var guardadoConExito = false

    private let service = EquipoService()

    init(usuarioId: UUID) {
        self.usuarioId = usuarioId
    }

    var catalogoFiltrado: [Equipo] {
        guard !busqueda.isEmpty else { return catalogo }
        return catalogo.filter { $0.nombre.localizedCaseInsensitiveContains(busqueda) }
    }

    /// Orden fijo para que las categorías no salten de lugar al filtrar.
    var categorias: [String] {
        let orden = ["peso_libre", "maquina", "cardio", "accesorio"]
        let presentes = Set(catalogoFiltrado.map(\.categoria))
        return orden.filter { presentes.contains($0) }
    }

    func equipoEnCategoria(_ categoria: String) -> [Equipo] {
        catalogoFiltrado.filter { $0.categoria == categoria }
    }

    func cargar() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let todo = service.fetchTodoElEquipo()
            async let delUsuario = service.fetchEquipoUsuario(usuarioId: usuarioId)
            catalogo = try await todo
            seleccionados = Set(try await delUsuario.map(\.id))
        } catch {
            errorMessage = "No se pudo cargar el catálogo de equipo."
        }
    }

    func toggle(_ equipo: Equipo) {
        if seleccionados.contains(equipo.id) {
            seleccionados.remove(equipo.id)
        } else {
            seleccionados.insert(equipo.id)
        }
    }

    func guardar() async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            try await service.actualizarEquipoUsuario(usuarioId: usuarioId, equipoIds: seleccionados)
            guardadoConExito = true
        } catch {
            errorMessage = "No se pudo guardar tu equipo. Intenta de nuevo."
        }
    }
}
