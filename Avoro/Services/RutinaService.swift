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

    enum CodingKeys: String, CodingKey {
        case id, nombre
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
                            grupo_muscular
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
}
