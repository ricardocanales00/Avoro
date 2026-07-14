import Foundation

/// Un mensaje dentro del chat de sustitución. Vive en la UI (no se persiste
/// en Supabase); el histórico se le vuelve a mandar a la Edge Function en
/// cada turno para que Gemini tenga contexto de la conversación.
struct MensajeChatSustitucion: Identifiable {
    enum Rol {
        case usuario
        case asistente
    }

    let id = UUID()
    let rol: Rol
    var texto: String
    var sugerencias: [SugerenciaEjercicio] = []
}

/// Una alternativa recomendada, ya resuelta contra el catálogo real
/// (no texto libre de Gemini) — por eso trae un `EjercicioResumen` completo.
struct SugerenciaEjercicio: Decodable, Identifiable {
    var id: UUID { ejercicio.id }
    let ejercicio: EjercicioResumen
    /// Versión corta — la que ya se usaba antes, pensada para el chat.
    let razon: String
    /// Párrafo más largo, generado por el mismo LLM, para el bottom sheet
    /// de detalles: qué es el ejercicio, qué trabaja, por qué es buena
    /// alternativa.
    let descripcion: String
    let seriesRecomendadas: Int?
    let repeticionesRecomendadas: Int?

    enum CodingKeys: String, CodingKey {
        case ejercicio, razon, descripcion
        case seriesRecomendadas = "series_recomendadas"
        case repeticionesRecomendadas = "repeticiones_recomendadas"
    }
}

/// Respuesta de la Edge Function `sustituir-ejercicio`.
struct RespuestaSustitucion: Decodable {
    let mensaje: String
    let sugerencias: [SugerenciaEjercicio]
}

// MARK: - Payloads de request

/// Turno de conversación tal como se le manda a la Edge Function (y de ahí
/// a Gemini). `role` usa el vocabulario de la API de Gemini ("user"/"model").
struct HistorialItemPayload: Encodable {
    let role: String
    let texto: String
}

struct SustitucionRequestPayload: Encodable {
    let usuarioId: UUID
    let ejercicioActualId: UUID
    let grupoMuscular: String
    let historial: [HistorialItemPayload]
}

// MARK: - Payloads para aplicar la sustitución en la base de datos

struct EjercicioIdUpdate: Encodable {
    let ejercicio_id: UUID
}

struct SustitucionEjercicioInsert: Encodable {
    let ejercicio_dia_id: UUID
    let ejercicio_original_id: UUID
    let ejercicio_sustituto_id: UUID
}
