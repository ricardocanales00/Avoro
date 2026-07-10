//
//  EncendiendoMotorView.swift
//  Avoro
//
//  Pantalla de transición full-screen (nuevo, esta sesión), mostrada al
//  elegir "Programa de varios días" en TipoRutinaView. Es puramente
//  decorativa: no llama a ningún backend todavía — la generación real
//  del plan (llamada a Groq) ocurrirá al final del wizard, en
//  `PlanIAGenerandoView`. Aquí solo se espera un tiempo fijo (8s) y se
//  navega automáticamente al wizard.
//

import SwiftUI

struct EncendiendoMotorView: View {
    @State private var irAWizard = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [ProgresaColor.primary, ProgresaColor.accent],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Text("Encendiendo\nel motor para\nsugerirte\nuna rutina")
                    .font(.system(size: 30, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)

                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                }
                .frame(width: 84, height: 84)
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $irAWizard) {
            PlanIAWizardView()
        }
        .task {
            // Duración fija de la transición: 8 segundos.
            try? await Task.sleep(nanoseconds: 8_000_000_000)
            irAWizard = true
        }
    }
}

#Preview {
    NavigationStack {
        EncendiendoMotorView()
    }
}
