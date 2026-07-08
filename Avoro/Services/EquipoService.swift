import Foundation
import Supabase

// MARK: - Payloads

private struct UsuarioEquipoInsert: Encodable {
    let usuario_id: UUID
    let equipo_id: UUID
}

private struct UsuarioEjercicioInsert: Encodable {
    let usuario_id: UUID
    let ejercicio_id: UUID
}

private struct UsuarioEquipoRow: Decodable {
    let equipo: Equipo
}

private struct UsuarioEjercicioRow: Decodable {
    let ejercicio_id: UUID
}

private struct UnidadPreferidaUpdate: Encodable {
    let unidad_preferida: String
}

// MARK: - Servicio

struct EquipoService {
    private let client = SupabaseService.shared.client

    /// Catálogo completo de equipo (para el picker de "¿Qué equipo tienes?").
    func fetchTodoElEquipo() async throws -> [Equipo] {
        try await client
            .from("equipo")
            .select()
            .order("categoria")
            .order("nombre")
            .execute()
            .value
    }

    /// Equipo que el usuario ya tiene marcado como disponible.
    func fetchEquipoUsuario(usuarioId: UUID) async throws -> [Equipo] {
        let filas: [UsuarioEquipoRow] = try await client
            .from("usuario_equipo")
            .select("equipo:equipo_id (id, nombre, categoria)")
            .eq("usuario_id", value: usuarioId)
            .execute()
            .value
        return filas.map(\.equipo)
    }

    /// Reemplaza el equipo disponible del usuario por el nuevo conjunto de
    /// ids. Hace un diff simple (borra lo que ya no está, inserta lo nuevo)
    /// en vez de un delete-all + insert-all, para no generar un instante
    /// sin filas si algo falla a la mitad.
    func actualizarEquipoUsuario(usuarioId: UUID, equipoIds nuevoConjunto: Set<UUID>) async throws {
        let actuales = try await fetchEquipoUsuario(usuarioId: usuarioId)
        let idsActuales = Set(actuales.map(\.id))

        let aQuitar = idsActuales.subtracting(nuevoConjunto)
        let aAgregar = nuevoConjunto.subtracting(idsActuales)

        if !aQuitar.isEmpty {
            try await client
                .from("usuario_equipo")
                .delete()
                .eq("usuario_id", value: usuarioId)
                .in("equipo_id", values: aQuitar.map { $0.uuidString })
                .execute()
        }

        if !aAgregar.isEmpty {
            let nuevos = aAgregar.map { UsuarioEquipoInsert(usuario_id: usuarioId, equipo_id: $0) }
            try await client
                .from("usuario_equipo")
                .insert(nuevos)
                .execute()
        }

        // Si se quitó equipo, cualquier ejercicio habilitado que dependiera
        // de ese equipo queda huérfano — lo limpiamos aquí en vez de dejar
        // que el trigger de la BD lo descubra en el siguiente insert (el
        // trigger solo valida en INSERT, no limpia filas existentes).
        if !aQuitar.isEmpty {
            try await limpiarEjerciciosSinEquipo(usuarioId: usuarioId)
        }
    }

    /// Ids de ejercicios que el usuario tiene explícitamente habilitados.
    func fetchEjerciciosHabilitados(usuarioId: UUID) async throws -> Set<UUID> {
        let filas: [UsuarioEjercicioRow] = try await client
            .from("usuario_ejercicio")
            .select("ejercicio_id")
            .eq("usuario_id", value: usuarioId)
            .execute()
            .value
        return Set(filas.map(\.ejercicio_id))
    }

    /// Mismo patrón de diff que `actualizarEquipoUsuario`. No valida aquí
    /// la regla de "el equipo debe estar en tu perfil" — esa regla la
    /// aplica la UI (solo muestra ejercicios de equipo ya seleccionado) y,
    /// como respaldo, el trigger `antes_de_insertar_usuario_ejercicio` en
    /// la base de datos.
    func actualizarEjerciciosHabilitados(usuarioId: UUID, ejercicioIds nuevoConjunto: Set<UUID>) async throws {
        let actuales = try await fetchEjerciciosHabilitados(usuarioId: usuarioId)

        let aQuitar = actuales.subtracting(nuevoConjunto)
        let aAgregar = nuevoConjunto.subtracting(actuales)

        if !aQuitar.isEmpty {
            try await client
                .from("usuario_ejercicio")
                .delete()
                .eq("usuario_id", value: usuarioId)
                .in("ejercicio_id", values: aQuitar.map { $0.uuidString })
                .execute()
        }

        if !aAgregar.isEmpty {
            let nuevos = aAgregar.map { UsuarioEjercicioInsert(usuario_id: usuarioId, ejercicio_id: $0) }
            try await client
                .from("usuario_ejercicio")
                .insert(nuevos)
                .execute()
        }
    }

    /// Catálogo completo de ejercicios cuyo equipo esté entre los ids dados
    /// — usado para poblar la lista de "elige tus ejercicios" filtrada al
    /// equipo que el usuario ya seleccionó.
    func fetchCatalogoPorEquipo(equipoIds: [UUID]) async throws -> [EjercicioResumen] {
        guard !equipoIds.isEmpty else { return [] }
        return try await client
            .from("ejercicio")
            .select("id, nombre, imagen_url, grupo_muscular, equipo:equipo_id (id, nombre, categoria)")
            .in("equipo_id", values: equipoIds.map { $0.uuidString })
            .order("grupo_muscular")
            .order("nombre")
            .execute()
            .value
    }

    func actualizarUnidadPreferida(usuarioId: UUID, unidad: String) async throws {
        try await client
            .from("perfiles")
            .update(UnidadPreferidaUpdate(unidad_preferida: unidad))
            .eq("id", value: usuarioId)
            .execute()
    }

    private func limpiarEjerciciosSinEquipo(usuarioId: UUID) async throws {
        // El trigger de la BD ya impide agregar nuevos, pero no borra los
        // que quedaron huérfanos al quitar equipo. Esta query trae los
        // habilitados y, del lado del cliente, filtra los que ya no
        // deberían estar — para un catálogo de este tamaño es aceptable
        // hacerlo en memoria en vez de un query SQL más elaborado.
        let habilitados = try await fetchEjerciciosHabilitados(usuarioId: usuarioId)
        guard !habilitados.isEmpty else { return }

        let equipoActual = Set(try await fetchEquipoUsuario(usuarioId: usuarioId).map(\.id))
        let catalogoHabilitado = try await fetchCatalogoPorEquipo(equipoIds: Array(equipoActual))
        let idsValidos = Set(catalogoHabilitado.map(\.id))

        let huerfanos = habilitados.subtracting(idsValidos)
        guard !huerfanos.isEmpty else { return }

        try await client
            .from("usuario_ejercicio")
            .delete()
            .eq("usuario_id", value: usuarioId)
            .in("ejercicio_id", values: huerfanos.map { $0.uuidString })
            .execute()
    }
}
