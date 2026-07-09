//
//  TipoRutinaView.swift
//  Avoro
//
//  Paso 2/4 del flujo de Modo Entrenador.
//

import SwiftUI

struct TipoRutinaView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var irAUnSoloDia = false
    @State private var irAProgramaVariosDias = false

    var body: some View {
        VStack(spacing: 0) {
            ModoEntrenadorHeader(paso: 2, onBack: { dismiss() })

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("¿Qué tipo de rutina quieres?")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(ProgresaColor.primary)
                    Text("Elige si entrenarás solo hoy o quieres un programa completo.")
                        .font(.subheadline)
                        .foregroundColor(ProgresaColor.textSecondary)
                }
                .padding(.top, 8)

                OpcionCard(
                    icono: "dumbbell",
                    colorIcono: ProgresaColor.primary,
                    colorFondoIcono: ProgresaColor.background,
                    titulo: "Un solo día",
                    subtitulo: "Una sesión para hoy. Tú eliges qué músculos trabajar."
                ) {
                    irAUnSoloDia = true
                }

                OpcionCard(
                    icono: "calendar",
                    colorIcono: .white,
                    colorFondoIcono: ProgresaColor.primary,
                    titulo: "Programa de varios días",
                    subtitulo: "Un plan semanal dividido por grupos musculares que se guardará en tus rutinas.",
                    destacada: true
                ) {
                    irAProgramaVariosDias = true
                }

                Spacer()
            }
            .padding(20)
        }
        .background(ProgresaColor.background)
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $irAUnSoloDia) {
            SeleccionMusculosView()
        }
        .navigationDestination(isPresented: $irAProgramaVariosDias) {
            ProgramaVariosDiasView()
        }
    }
}

#Preview {
    NavigationStack {
        TipoRutinaView()
    }
}
