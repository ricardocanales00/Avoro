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

/// Payload de inserción. Antes dependía del default `current_date` de la
/// columna en Postgres, pero eso rompe el backdating: si el usuario navega
/// a una fecha pasada en el calendario e inicia esa rutina, el registro
/// debe guardarse con ESA fecha, no con la fecha real del dispositivo.
struct NuevoRegistroEntrenamiento: Encodable {
    let ejercicio_dia_id: UUID
    let usuario_id: UUID
    let fecha: String
    let numero_serie: Int
    let repeticiones_reales: Int
    let peso: Double
    let unidad: String
}
