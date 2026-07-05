import Foundation
import Supabase

// MARK: - DTOs específicos de este query anidado
// Son distintos de los Models "puros" 1:1 con cada tabla porque aquí
// traemos rutina -> dia_rutina -> ejercicio_dia -> ejercicio en una sola
// llamada (join anidado de PostgREST), lo que evita hacer 4 queries
// separados y esperar en cascada.

struct RutinaConDias: Codable, Identifiable {
    let id: UUID
    let nombre: String
    let descripcion: String?
    /// Postgres regresa `date` como "YYYY-MM-DD", no como timestamp ISO8601,
    /// así que lo dejamos como String y lo parseamos nosotros (ver abajo)
    /// para no depender de la estrategia de fecha del decoder del SDK.
    let fechaInicio: String
    let fechaFin: String?
    let activa: Bool
    let dias: [DiaConEjercicios]

    enum CodingKeys: String, CodingKey {
        case id, nombre, descripcion
        case fechaInicio = "fecha_inicio"
        case fechaFin = "fecha_fin"
        case activa
        case dias = "dia_rutina"
    }

    var fechaInicioComoDate: Date {
        RutinaConDias.formatoFecha.date(from: fechaInicio) ?? Date()
    }
    
    var fechaFinComoDate: Date? {
        guard let fechaFin else { return nil }
        return RutinaConDias.formatoFecha.date(from: fechaFin)
    }

    private static let formatoFecha: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()
}

struct DiaConEjercicios: Codable, Identifiable {
    let id: UUID
    let nombreDia: String
    let orden: Int
    let ejercicios: [EjercicioDiaConEjercicio]

    enum CodingKeys: String, CodingKey {
        case id
        case nombreDia = "nombre_dia"
        case orden
        case ejercicios = "ejercicio_dia"
    }
}

struct EjercicioDiaConEjercicio: Codable, Identifiable {
    let id: UUID
    let seriesObjetivo: Int
    let repeticionesObjetivo: Int
    let orden: Int
    let ejercicio: EjercicioResumen

    enum CodingKeys: String, CodingKey {
        case id
        case seriesObjetivo = "series_objetivo"
        case repeticionesObjetivo = "repeticiones_objetivo"
        case orden
        case ejercicio
    }
}

struct EjercicioResumen: Codable, Identifiable {
    let id: UUID
    let nombre: String
    let imagenUrl: String?
    let grupoMuscular: String
    /// Viene del join `ejercicio.equipo_id -> equipo.id` (ver los `.select()`
    /// más abajo). Es opcional porque en tu esquema `equipo_id` admite null.
    let equipo: Equipo?

    enum CodingKeys: String, CodingKey {
        case id, nombre, equipo
        case imagenUrl = "imagen_url"
        case grupoMuscular = "grupo_muscular"
    }
}

// MARK: - Servicio

struct RutinaService {
    private let client = SupabaseService.shared.client

    /// Trae la rutina activa del usuario con toda su estructura anidada
    /// (días -> ejercicios -> catálogo de ejercicio) en un solo query.
    func fetchRutinaActiva(usuarioId: UUID) async throws -> RutinaConDias? {
        let rutinas: [RutinaConDias] = try await client
            .from("rutina")
            .select("""
                id,
                nombre,
                descripcion,
                fecha_inicio,
                fecha_fin,
                activa,
                dia_rutina (
                    id,
                    nombre_dia,
                    orden,
                    ejercicio_dia (
                        id,
                        series_objetivo,
                        repeticiones_objetivo,
                        orden,
                        ejercicio (
                            id,
                            nombre,
                            imagen_url,
                            grupo_muscular,
                            equipo (
                                id,
                                nombre,
                                categoria
                            )
                        )
                    )
                )
                """)
            .eq("usuario_id", value: usuarioId)
            .eq("activa", value: true)
            .limit(1)
            .execute()
            .value

        return rutinas.first
    }
    
    /// Trae TODAS las rutinas del usuario con sus días y ejercicios anidados,
    /// para poder mostrar la correcta según la fecha que se navegue en Home.
    func fetchTodasConDias(usuarioId: UUID) async throws -> [RutinaConDias] {
        try await client
            .from("rutina")
            .select("""
                id,
                nombre,
                descripcion,
                fecha_inicio,
                fecha_fin,
                activa,
                dia_rutina (
                    id,
                    nombre_dia,
                    orden,
                    ejercicio_dia (
                        id,
                        series_objetivo,
                        repeticiones_objetivo,
                        orden,
                        ejercicio (
                            id,
                            nombre,
                            imagen_url,
                            grupo_muscular,
                            equipo ( id, nombre, categoria )
                        )
                    )
                )
                """)
            .eq("usuario_id", value: usuarioId)
            .execute()
            .value
    }

    /// Cuenta cuántas rutinas totales tiene el usuario (para el texto
    /// "N rutinas guardadas" en la card de Home).
    func contarRutinas(usuarioId: UUID) async throws -> Int {
        let respuesta = try await client
            .from("rutina")
            .select("id", head: true, count: .exact)
            .eq("usuario_id", value: usuarioId)
            .execute()

        return respuesta.count ?? 0
    }

    // MARK: - CRUD de Rutina (Épica 2)

    func fetchRutinas(usuarioId: UUID) async throws -> [Rutina] {
        try await client
            .from("rutina")
            .select()
            .eq("usuario_id", value: usuarioId)
            .order("fecha_inicio", ascending: false)
            .execute()
            .value
    }

    @discardableResult
    func crearRutina(_ nueva: RutinaInsert) async throws -> Rutina {
        try await client
            .from("rutina")
            .insert(nueva)
            .select()
            .single()
            .execute()
            .value
    }

    func actualizarRutina(id: UUID, cambios: RutinaUpdate) async throws {
        try await client
            .from("rutina")
            .update(cambios)
            .eq("id", value: id)
            .execute()
    }

    func eliminarRutina(id: UUID) async throws {
        try await client
            .from("rutina")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    // MARK: - CRUD de días de rutina (Épica 3)

    /// Trae los días de una rutina con sus ejercicios anidados, para el
    /// editor de estructura. A diferencia de `fetchRutinaActiva`, aquí no
    /// filtramos por `activa` porque el usuario puede editar cualquiera
    /// de sus rutinas, no solo la activa.
    func fetchDiasConEjercicios(rutinaId: UUID) async throws -> [DiaConEjercicios] {
        let dias: [DiaConEjercicios] = try await client
            .from("dia_rutina")
            .select("""
                id,
                nombre_dia,
                orden,
                ejercicio_dia (
                    id,
                    series_objetivo,
                    repeticiones_objetivo,
                    orden,
                    ejercicio (
                        id,
                        nombre,
                        imagen_url,
                        grupo_muscular,
                        equipo (
                            id,
                            nombre,
                            categoria
                        )
                    )
                )
                """)
            .eq("rutina_id", value: rutinaId)
            .order("orden")
            .execute()
            .value

        return dias
    }

    @discardableResult
    func crearDia(_ nuevo: DiaRutinaInsert) async throws -> DiaRutina {
        try await client
            .from("dia_rutina")
            .insert(nuevo)
            .select()
            .single()
            .execute()
            .value
    }

    func renombrarDia(id: UUID, nombreDia: String) async throws {
        try await client
            .from("dia_rutina")
            .update(DiaRutinaNombreUpdate(nombreDia: nombreDia))
            .eq("id", value: id)
            .execute()
    }

    func actualizarOrdenDia(id: UUID, orden: Int) async throws {
        try await client
            .from("dia_rutina")
            .update(OrdenUpdate(orden: orden))
            .eq("id", value: id)
            .execute()
    }

    func eliminarDia(id: UUID) async throws {
        try await client
            .from("dia_rutina")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    // MARK: - CRUD de ejercicios dentro de un día (Épica 3)

    @discardableResult
    func agregarEjercicioADia(_ nuevo: EjercicioDiaInsert) async throws -> EjercicioDiaConEjercicio {
        try await client
            .from("ejercicio_dia")
            .insert(nuevo)
            .select("""
                id,
                series_objetivo,
                repeticiones_objetivo,
                orden,
                ejercicio (
                    id,
                    nombre,
                    imagen_url,
                    grupo_muscular,
                    equipo (
                        id,
                        nombre,
                        categoria
                    )
                )
                """)
            .single()
            .execute()
            .value
    }

    func actualizarSeriesReps(id: UUID, series: Int, repeticiones: Int) async throws {
        try await client
            .from("ejercicio_dia")
            .update(EjercicioDiaSeriesUpdate(seriesObjetivo: series, repeticionesObjetivo: repeticiones))
            .eq("id", value: id)
            .execute()
    }

    func actualizarOrdenEjercicioDia(id: UUID, orden: Int) async throws {
        try await client
            .from("ejercicio_dia")
            .update(OrdenUpdate(orden: orden))
            .eq("id", value: id)
            .execute()
    }

    func eliminarEjercicioDia(id: UUID) async throws {
        try await client
            .from("ejercicio_dia")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Catálogo de ejercicios (Épica 7, para el picker)

    func fetchCatalogoEjercicios() async throws -> [EjercicioResumen] {
        try await client
            .from("ejercicio")
            .select("id, nombre, imagen_url, grupo_muscular, equipo (id, nombre, categoria)")
            .order("grupo_muscular")
            .execute()
            .value
    }
}
