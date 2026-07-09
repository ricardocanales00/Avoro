//
//  RutinaGuardadaView.swift
//  Avoro
//
//  Última pantalla de la rama "Programa de varios días". Muestra el
//  resumen con los datos que el usuario ya había capturado en el paso
//  anterior — no hay ningún guardado real en Supabase detrás.
//

import SwiftUI

struct RutinaGuardadaView: View {
    @Environment(\.dismiss) private var dismiss
    let nombreRutina: String
    let totalDias: Int
    let primerDia: String

    var body: some View {
        VStack(spacing: 0) {
            ModoEntrenadorHeader(paso: 4, onBack: { dismiss() })

            VStack(spacing: 20) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(ProgresaColor.accent.opacity(0.15))
                        .frame(width: 72, height: 72)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(ProgresaColor.accent)
                }

                VStack(spacing: 8) {
                    Text("¡Rutina guardada!")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(ProgresaColor.primary)
                    Text("Tu programa sugerido ya está en tus rutinas y quedó marcado como activo. Puedes empezar ahora mismo.")
                        .font(.subheadline)
                        .foregroundColor(ProgresaColor.textSecondary)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .foregroundColor(ProgresaColor.primary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(nombreRutina)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(ProgresaColor.primary)
                        Text("\(totalDias) días · comienza con \(primerDia)")
                            .font(.footnote)
                            .foregroundColor(ProgresaColor.textSecondary)
                    }
                    Spacer()
                }
                .padding(14)
                .background(ProgresaColor.surface)
                .cornerRadius(14)

                Spacer()

                Button {
                    // TODO: crear la rutina/días/ejercicios reales en
                    // Supabase y navegar a EjecucionRutinaView — sin
                    // funcionalidad todavía; este flujo termina aquí.
                } label: {
                    Label("Iniciar entrenamiento", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ProgresaPrimaryButtonStyle())
            }
            .padding(20)
        }
        .background(ProgresaColor.background)
        .navigationBarHidden(true)
    }
}

#Preview {
    NavigationStack {
        RutinaGuardadaView(nombreRutina: "Rutina sugerida", totalDias: 3, primerDia: "Día 1 · Empuje")
    }
}
