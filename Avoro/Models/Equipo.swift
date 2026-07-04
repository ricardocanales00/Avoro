//
//  Equipo.swift
//  Avoro
//
//  Created by Ricardo Canales on 04/07/26.
//

import Foundation

struct Equipo : Codable, Identifiable {
    let id: UUID
    let nombre: String
    let categoria: String
}
