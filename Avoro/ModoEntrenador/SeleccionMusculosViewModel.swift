//
//  SeleccionMusculosViewModel.swift
//  Avoro
//

import Foundation
import Supabase
import Combine

@MainActor
final class SeleccionMusculosViewModel: ObservableObject {
    /// Valores reales de `grupo_muscular` que existen en el catálogo de
    /// ejercicios (en minúsculas, tal como se guardan). No es una lista
    /// hardcodeada: es el único punto de este flujo que sí consulta
    /// Supabase, para no ofrecer músculos sin ejercicios cargados.
    @Published private(set) var gruposDisponibles: Set<String> = []
    @Published var isLoading = true

    private let client = SupabaseService.shared.client

    func cargarGruposMusculares() async {
        isLoading = true
        defer { isLoading = false }

        struct Fila: Decodable {
            let grupo_muscular: String
        }

        do {
            let filas: [Fila] = try await client
                .from("ejercicio")
                .select("grupo_muscular")
                .execute()
                .value
            gruposDisponibles = Set(filas.map { $0.grupo_muscular.lowercased() })
        } catch {
            // Si falla la consulta, dejamos el set vacío — la vista se
            // encarga de no mostrar ninguna categoría en ese caso, en vez
            // de tronar o mostrar músculos que quizá no existan.
            gruposDisponibles = []
        }
    }
}
