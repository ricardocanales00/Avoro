import Foundation
import Supabase

struct RegistroService {
    private let client = SupabaseService.shared.client

    /// Inserta todas las series capturadas de un ejercicio en una sola llamada.
    func crearRegistros(_ registros: [NuevoRegistroEntrenamiento]) async throws {
        try await client
            .from("registro_entrenamiento")
            .insert(registros)
            .execute()
    }

    /// Trae los registros de HOY para un conjunto de ejercicio_dia, para
    /// saber qué ejercicios ya se completaron si el usuario reabre la
    /// pantalla de ejecución a medio entrenamiento.
    /// Trae los registros guardados para una fecha específica (puede ser
    /// hoy o una fecha pasada, si el usuario está registrando de forma
    /// retroactiva). Antes esta función asumía siempre "hoy" — ahora la
    /// fecha la decide quien llama.
    func fetchRegistros(ejercicioDiaIds: [UUID], fecha: String) async throws -> [RegistroEntrenamiento] {
        guard !ejercicioDiaIds.isEmpty else { return [] }

        return try await client
            .from("registro_entrenamiento")
            .select()
            .in("ejercicio_dia_id", values: ejercicioDiaIds)
            .eq("fecha", value: fecha)
            .execute()
            .value
    }

    /// Trae todos los registros del usuario dentro de un rango de fechas
    /// (usado por Home para saber qué días de la semana visible ya se
    /// completaron y pintar el punto de progreso en el calendario).
    func fetchRegistrosEntreFechas(usuarioId: UUID, desde: String, hasta: String) async throws -> [RegistroEntrenamiento] {
        try await client
            .from("registro_entrenamiento")
            .select()
            .eq("usuario_id", value: usuarioId)
            .gte("fecha", value: desde)
            .lte("fecha", value: hasta)
            .execute()
            .value
    }
}
