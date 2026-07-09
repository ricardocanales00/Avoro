//
//  RutinaUnDiaPropuestaView.swift
//  Avoro
//
//  Paso 4/4, rama "Un solo día". El contenido de `ejercicios` es de
//  ejemplo (no se genera con IA todavía); reordenar/sustituir/eliminar
//  son solo estado local en memoria, no tocan Supabase.
//

import SwiftUI

struct RutinaUnDiaPropuestaView: View {
    @Environment(\.dismiss) private var dismiss
    let musculosSeleccionados: [String]

    @State private var ejercicios: [EjercicioMock] = [
        EjercicioMock(nombre: "Curl femoral tumbado", series: 3, reps: 12, musculo: "Femoral"),
        EjercicioMock(nombre: "Sentadilla", series: 4, reps: 10, musculo: "Cuádriceps"),
        EjercicioMock(nombre: "Prensa de piernas", series: 4, reps: 10, musculo: "Cuádriceps"),
        EjercicioMock(nombre: "Elevación de pantorrillas", series: 4, reps: 15, musculo: "Pantorrilla"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            ModoEntrenadorHeader(paso: 4, onBack: { dismiss() })

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "wand.and.stars")
                            .foregroundColor(ProgresaColor.accent)
                        Text("Esta es tu rutina propuesta. Reacomoda, quita, sustituye o agrega ejercicios.")
                            .font(.subheadline)
                            .foregroundColor(ProgresaColor.primary)
                    }
                    .padding(14)
                    .background(ProgresaColor.accent.opacity(0.12))
                    .cornerRadius(14)

                    Text("Ejercicios (\(ejercicios.count))")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(ProgresaColor.primary)

                    VStack(spacing: 10) {
                        ForEach(Array(ejercicios.enumerated()), id: \.element.id) { index, ejercicio in
                            EjercicioMockRow(
                                ejercicio: ejercicio,
                                puedeSubir: index > 0,
                                puedeBajar: index < ejercicios.count - 1,
                                onSubir: { mover(index, -1) },
                                onBajar: { mover(index, 1) },
                                onSustituir: {
                                    // TODO: sustitución real vía la Edge
                                    // Function existente — sin funcionalidad
                                    // todavía en este flujo.
                                },
                                onEliminar: { ejercicios.remove(at: index) }
                            )
                        }
                    }

                    Button {
                        // TODO: agregar ejercicio desde el catálogo — sin
                        // funcionalidad todavía.
                    } label: {
                        Label("Agregar ejercicio", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(ProgresaOutlineButtonStyle())
                }
                .padding(20)
                .padding(.bottom, 100)
            }
        }
        .background(ProgresaColor.background)
        .navigationBarHidden(true)
        .safeAreaInset(edge: .bottom) {
            Button {
                // TODO: crear rutina/día/ejercicio_dia reales en Supabase
                // y navegar a EjecucionRutinaView — sin funcionalidad
                // todavía; este flujo termina aquí.
            } label: {
                Label("Iniciar rutina", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(ProgresaPrimaryButtonStyle())
            .padding(16)
            .background(ProgresaColor.surface)
        }
    }

    private func mover(_ index: Int, _ delta: Int) {
        let nuevoIndice = index + delta
        guard ejercicios.indices.contains(nuevoIndice) else { return }
        ejercicios.swapAt(index, nuevoIndice)
    }
}

#Preview {
    NavigationStack {
        RutinaUnDiaPropuestaView(musculosSeleccionados: ["Cuádriceps", "Femoral"])
    }
}
