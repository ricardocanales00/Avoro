import Foundation
import Supabase

struct SustitucionService {
    private let client = SupabaseService.shared.client

    /// Llama a la Edge Function `sustituir-ejercicio`, que a su vez arma el
    /// catálogo candidato (grupo muscular + equipo del usuario) y le pregunta
    /// a Gemini. Se le manda todo el historial de la conversación en cada
    /// turno porque la función es stateless (no guarda sesión de chat).
    func pedirSugerencias(
        usuarioId: UUID,
        ejercicioActualId: UUID,
        grupoMuscular: String,
        historial: [HistorialItemPayload]
    ) async throws -> RespuestaSustitucion {
        let payload = SustitucionRequestPayload(
            usuarioId: usuarioId,
            ejercicioActualId: ejercicioActualId,
            grupoMuscular: grupoMuscular,
            historial: historial
        )

        // NOTA: la firma exacta de `functions.invoke` varía un poco entre
        // versiones de supabase-swift. Esta es la forma típica en v2.x; si tu
        // versión instalada difiere, Xcode debería sugerir el ajuste (por
        // ejemplo, algunas versiones piden codificar `payload` a `Data` con
        // `JSONEncoder` en vez de aceptar el `Encodable` directo).
        return try await client.functions.invoke(
            "sustituir-ejercicio",
            options: FunctionInvokeOptions(body: payload)
        )
    }

    /// Aplica la sustitución: cambia el `ejercicio_id` de la fila
    /// `ejercicio_dia` (conserva series/repeticiones/orden tal cual) y deja
    /// trazabilidad en `sustitucion_ejercicio`.
    func sustituirEjercicio(
        ejercicioDiaId: UUID,
        ejercicioOriginalId: UUID,
        ejercicioSustitutoId: UUID
    ) async throws {
        try await client
            .from("ejercicio_dia")
            .update(EjercicioIdUpdate(ejercicio_id: ejercicioSustitutoId))
            .eq("id", value: ejercicioDiaId)
            .execute()

        try await client
            .from("sustitucion_ejercicio")
            .insert(
                SustitucionEjercicioInsert(
                    ejercicio_dia_id: ejercicioDiaId,
                    ejercicio_original_id: ejercicioOriginalId,
                    ejercicio_sustituto_id: ejercicioSustitutoId
                )
            )
            .execute()
    }
}
