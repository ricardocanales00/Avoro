import Foundation
import Combine

@MainActor
final class EditarEjerciciosViewModel: ObservableObject {
    let usuarioId: UUID

    /// Ya viene filtrado por el equipo que el usuario tiene seleccionado
    /// (ver `EquipoService.fetchCatalogoPorEquipo`) — nunca se muestra aquí
    /// un ejercicio de un equipo que el usuario no tiene, así que la regla
    /// "no puedes elegir un ejercicio sin su máquina" queda garantizada
    /// por construcción, no por validación posterior.
    @Published var catalogo: [EjercicioResumen] = []
    @Published var seleccionados: Set<UUID> = []
    @Published var busqueda = ""
    @Published var isLoading = true
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var guardadoConExito = false

    /// `true` si el usuario todavía no tiene NINGÚN equipo seleccionado —
    /// en ese caso no hay nada que mostrar aquí todavía.
    @Published var sinEquipoConfigurado = false

    private let service = EquipoService()

    init(usuarioId: UUID) {
        self.usuarioId = usuarioId
    }

    var catalogoFiltrado: [EjercicioResumen] {
        guard !busqueda.isEmpty else { return catalogo }
        return catalogo.filter {
            $0.nombre.localizedCaseInsensitiveContains(busqueda) ||
            $0.grupoMuscular.localizedCaseInsensitiveContains(busqueda)
        }
    }

    var gruposMusculares: [String] {
        Array(Set(catalogoFiltrado.map(\.grupoMuscular))).sorted()
    }

    func ejerciciosEnGrupo(_ grupo: String) -> [EjercicioResumen] {
        catalogoFiltrado.filter { $0.grupoMuscular == grupo }
    }

    func cargar() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let equipoUsuario = try await service.fetchEquipoUsuario(usuarioId: usuarioId)

            guard !equipoUsuario.isEmpty else {
                sinEquipoConfigurado = true
                catalogo = []
                return
            }
            sinEquipoConfigurado = false

            async let cat = service.fetchCatalogoPorEquipo(equipoIds: equipoUsuario.map(\.id))
            async let habilitados = service.fetchEjerciciosHabilitados(usuarioId: usuarioId)

            catalogo = try await cat
            seleccionados = try await habilitados
        } catch {
            errorMessage = "No se pudo cargar tus ejercicios."
        }
    }

    func toggle(_ ejercicio: EjercicioResumen) {
        if seleccionados.contains(ejercicio.id) {
            seleccionados.remove(ejercicio.id)
        } else {
            seleccionados.insert(ejercicio.id)
        }
    }

    func guardar() async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            try await service.actualizarEjerciciosHabilitados(usuarioId: usuarioId, ejercicioIds: seleccionados)
            guardadoConExito = true
        } catch {
            errorMessage = "No se pudo guardar tus ejercicios. Intenta de nuevo."
        }
    }
}
