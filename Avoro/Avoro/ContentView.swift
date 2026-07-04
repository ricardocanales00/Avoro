//
//  ContentView.swift
//  Avoro
//
//  Created by Ricardo Canales on 04/07/26.
//

import SwiftUI
import Supabase

struct ContentView: View {
    @State private var equipos: [Equipo] = []
    @State private var mensaje = "Sin probar aún"

    var body: some View {
        VStack(spacing: 16) {
            Text(mensaje)
            List(equipos) { equipo in
                Text(equipo.nombre)
            }
        }
        .task {
            await cargarEquipo()
        }
    }

    func cargarEquipo() async {
        do {
            let resultado: [Equipo] = try await SupabaseService.shared.client
                .from("equipo")
                .select()
                .execute()
                .value
            equipos = resultado
            mensaje = "Conectado. \(resultado.count) equipos encontrados."
        } catch {
            mensaje = "Error: \(error.localizedDescription)"
        }
    }
}
