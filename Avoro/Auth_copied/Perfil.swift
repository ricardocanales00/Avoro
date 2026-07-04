import Foundation

/// Refleja la tabla public.perfiles
struct Perfil: Codable, Identifiable {
    let id: UUID
    var nombre: String
    var rol: String
    var unidadPreferida: String

    enum CodingKeys: String, CodingKey {
        case id
        case nombre
        case rol
        case unidadPreferida = "unidad_preferida"
    }
}
