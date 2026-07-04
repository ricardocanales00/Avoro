import Foundation

struct EjercicioDiaInsert: Encodable {
    let diaRutinaId: UUID
    let ejercicioId: UUID
    let seriesObjetivo: Int
    let repeticionesObjetivo: Int
    let orden: Int

    enum CodingKeys: String, CodingKey {
        case diaRutinaId = "dia_rutina_id"
        case ejercicioId = "ejercicio_id"
        case seriesObjetivo = "series_objetivo"
        case repeticionesObjetivo = "repeticiones_objetivo"
        case orden
    }
}

struct EjercicioDiaSeriesUpdate: Encodable {
    let seriesObjetivo: Int
    let repeticionesObjetivo: Int

    enum CodingKeys: String, CodingKey {
        case seriesObjetivo = "series_objetivo"
        case repeticionesObjetivo = "repeticiones_objetivo"
    }
}
