import Foundation

struct Rutina: Codable, Identifiable, Hashable {
    let id: UUID
    var nombre: String
    var descripcion: String?
    var fechaInicio: String
    var fechaFin: String?
    var activa: Bool
    /// Cada cuántos días naturales se repite el ciclo de la rutina (ej. 7
    /// = semanal, 14 = quincenal). Los días de entrenamiento (`dia_rutina`)
    /// usan su `orden` como posición dentro de este ciclo (orden 1 ->
    /// posición 0, orden 2 -> posición 1, ...); cualquier posición del
    /// ciclo sin un día asignado es automáticamente un día de descanso.
    var cicloDias: Int

    enum CodingKeys: String, CodingKey {
        case id, nombre, descripcion, activa
        case fechaInicio = "fecha_inicio"
        case fechaFin = "fecha_fin"
        case cicloDias = "ciclo_dias"
    }

    static let formatoFecha: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    var fechaInicioComoDate: Date {
        Rutina.formatoFecha.date(from: fechaInicio) ?? Date()
    }

    var fechaFinComoDate: Date? {
        guard let fechaFin else { return nil }
        return Rutina.formatoFecha.date(from: fechaFin)
    }
}

/// Payload para crear una rutina nueva (sin id, lo genera Postgres).
struct RutinaInsert: Encodable {
    let usuarioId: UUID
    let nombre: String
    let descripcion: String?
    let fechaInicio: String
    let fechaFin: String?
    let activa: Bool
    let cicloDias: Int

    enum CodingKeys: String, CodingKey {
        case usuarioId = "usuario_id"
        case nombre, descripcion, activa
        case fechaInicio = "fecha_inicio"
        case fechaFin = "fecha_fin"
        case cicloDias = "ciclo_dias"
    }
}

/// Payload para editar una rutina existente.
struct RutinaUpdate: Encodable {
    let nombre: String
    let descripcion: String?
    let fechaInicio: String
    let fechaFin: String?
    let activa: Bool
    let cicloDias: Int

    enum CodingKeys: String, CodingKey {
        case nombre, descripcion, activa
        case fechaInicio = "fecha_inicio"
        case fechaFin = "fecha_fin"
        case cicloDias = "ciclo_dias"
    }
}
