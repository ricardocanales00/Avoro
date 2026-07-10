//
//  PlanIAGenerandoView.swift
//  Avoro
//
//  Última pantalla del wizard (categoría "generando", nuevo esta sesión).
//  Muestra una animación de checklist secuencial y, al terminar, un botón
//  "Ver mi rutina" que navega a `ProgramaVariosDiasView` — la pantalla de
//  resumen/edición que ya existía (mock data, sin persistir en Supabase).
//
//  TODO (deuda técnica intencional de esta sesión): la animación de
//  checklist es puramente visual y con tiempos fijos; no hay ninguna
//  llamada real a Groq todavía. Cuando se conecte, las respuestas ya
//  están disponibles en `viewModel` (objetivoPrincipal, tiempoPorSesion,
//  diasPorSemana, experiencia, gruposPriorizar, gruposEvitar,
//  lugarEntrenamiento, lesiones, intensidad, cardio) para armar el prompt,
//  y esta vista debería esperar la respuesta real en vez de un `sleep`
//  fijo antes de mostrar "Ver mi rutina".
//

import SwiftUI

struct PlanIAGenerandoView: View {
    @ObservedObject var viewModel: PlanIAViewModel

    @State private var pasosCompletados: [Bool] = [false, false, false, false]
    @State private var terminado = false
    @State private var irARutina = false

    private let pasos = [
        "Analizando tu objetivo",
        "Ajustando volumen a tus días",
        "Seleccionando ejercicios",
        "Equilibrando grupos musculares",
    ]

    var body: some View {
        VStack(spacing: 24) {
            PlanIACategoriaHeader(categoriaActual: .generando, subPasoActual: 0, totalSubPasos: 0)

            Spacer()

            ZStack {
                Circle().fill(ProgresaColor.background)
                Image(systemName: "sparkles")
                    .font(.system(size: 30))
                    .foregroundColor(ProgresaColor.primary)
            }
            .frame(width: 90, height: 90)

            VStack(spacing: 6) {
                Text(terminado ? "¡Tu plan está listo!" : "Construyendo\ntu plan...")
                    .font(.system(size: 26, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(ProgresaColor.primary)

                if !terminado {
                    Text("Estamos armando cada sesión para ti.")
                        .font(.subheadline)
                        .foregroundColor(ProgresaColor.textSecondary)
                } else {
                    Text("Diseñado a partir de todo lo que nos contaste.")
                        .font(.subheadline)
                        .foregroundColor(ProgresaColor.textSecondary)
                }
            }
            .multilineTextAlignment(.center)

            VStack(spacing: 10) {
                ForEach(Array(pasos.enumerated()), id: \.offset) { index, texto in
                    HStack(spacing: 10) {
                        ZStack {
                            Circle().fill(pasosCompletados[index] ? ProgresaColor.accent : ProgresaColor.border)
                            if pasosCompletados[index] {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(width: 22, height: 22)

                        Text(texto)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(ProgresaColor.primary)

                        Spacer()
                    }
                    .padding(12)
                    .background(pasosCompletados[index] ? ProgresaColor.accent.opacity(0.12) : ProgresaColor.surface)
                    .cornerRadius(12)
                }
            }

            Spacer()

            if terminado {
                Button {
                    irARutina = true
                } label: {
                    Text("Ver mi rutina")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ProgresaPrimaryButtonStyle())
            }
        }
        .padding(20)
        .background(ProgresaColor.background)
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $irARutina) {
            ProgramaVariosDiasView()
        }
        .task {
            for index in pasosCompletados.indices {
                try? await Task.sleep(nanoseconds: 900_000_000)
                withAnimation { pasosCompletados[index] = true }
            }
            try? await Task.sleep(nanoseconds: 300_000_000)
            withAnimation { terminado = true }
        }
    }
}

#Preview {
    NavigationStack {
        PlanIAGenerandoView(viewModel: PlanIAViewModel())
    }
}
