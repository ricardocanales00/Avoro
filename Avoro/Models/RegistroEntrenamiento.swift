import Foundation

struct RegistroEntrenamiento: Codable, Identifiable {
    let id: UUID
    let ejercicioDiaId: UUID
    let usuarioId: UUID
    let fecha: String
    let numeroSerie: Int
    let repeticionesReales: Int
    let peso: Double
    let unidad: String

    enum CodingKeys: String, CodingKey {
        case id
        case ejercicioDiaId = "ejercicio_dia_id"
        case usuarioId = "usuario_id"
        case fecha
        case numeroSerie = "numero_serie"
        case repeticionesReales = "repeticiones_reales"
        case peso, unidad
    }
}

/// Payload de inserción. No mandamos `fecha`: la columna tiene
/// `default current_date` en el schema, así que Postgres la asigna sola.
struct NuevoRegistroEntrenamiento: Encodable {
    let ejercicio_dia_id: UUID
    let usuario_id: UUID
    let numero_serie: Int
    let repeticiones_reales: Int
    let peso: Double
    let unidad: String
}
