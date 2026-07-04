import Foundation

struct DiaRutina: Codable, Identifiable, Hashable {
    let id: UUID
    var nombreDia: String
    var orden: Int

    enum CodingKeys: String, CodingKey {
        case id, orden
        case nombreDia = "nombre_dia"
    }
}

struct DiaRutinaInsert: Encodable {
    let rutinaId: UUID
    let nombreDia: String
    let orden: Int

    enum CodingKeys: String, CodingKey {
        case rutinaId = "rutina_id"
        case nombreDia = "nombre_dia"
        case orden
    }
}

struct DiaRutinaNombreUpdate: Encodable {
    let nombreDia: String

    enum CodingKeys: String, CodingKey {
        case nombreDia = "nombre_dia"
    }
}

struct OrdenUpdate: Encodable {
    let orden: Int
}
