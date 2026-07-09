//
//  ProgramaVariosDiasView.swift
//  Avoro
//
//  Combina las capturas 4 y 5 (son la misma pantalla, una es scroll de la
//  otra) en una sola vista con ScrollView. La estructura de "Días y
//  ejercicios" reutiliza el patrón de EstructuraRutinaView.DiaRow (nombre
//  del día + conteo de ejercicios), extendido con expandir/colapsar para
//  mostrar los ejercicios inline en vez de navegar a DiaEditorView — este
//  flujo no persiste nada en Supabase todavía, así que no tiene sentido
//  navegar a un editor real.
//

import SwiftUI

private struct DiaMock: Identifiable {
    let id = UUID()
    var nombre: String
    var musculos: String
    var ejercicios: [EjercicioMock]
}

struct ProgramaVariosDiasView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var nombreRutina = "Rutina sugerida"
    @State private var descripcion = ""
    @State private var fechaInicio = Date()
    @State private var fechaFin = Calendar.current.date(byAdding: .day, value: 25, to: Date()) ?? Date()
    @State private var tieneFechaFin = true
    @State private var esActiva = true
    @State private var diaExpandido: UUID?
    @State private var irAGuardada = false

    @State private var dias: [DiaMock] = [
        DiaMock(nombre: "Día 1 · Empuje", musculos: "Pecho, Hombro, Tríceps", ejercicios: [
            EjercicioMock(nombre: "Press de banca", series: 4, reps: 10, musculo: "Pecho"),
            EjercicioMock(nombre: "Press inclinado con mancuerna", series: 4, reps: 10, musculo: "Pecho"),
            EjercicioMock(nombre: "Press militar", series: 3, reps: 12, musculo: "Hombro"),
            EjercicioMock(nombre: "Elevaciones laterales", series: 3, reps: 12, musculo: "Hombro"),
            EjercicioMock(nombre: "Extensión de tríceps", series: 3, reps: 12, musculo: "Tríceps"),
        ]),
        DiaMock(nombre: "Día 2 · Tirón", musculos: "Espalda, Bíceps", ejercicios: [
            EjercicioMock(nombre: "Remo con barra", series: 4, reps: 10, musculo: "Espalda"),
            EjercicioMock(nombre: "Jalón al pecho", series: 4, reps: 10, musculo: "Espalda"),
            EjercicioMock(nombre: "Curl con barra Z", series: 3, reps: 12, musculo: "Bíceps"),
        ]),
        DiaMock(nombre: "Día 3 · Pierna", musculos: "Cuádriceps, Femoral, Glúteo", ejercicios: [
            EjercicioMock(nombre: "Sentadilla", series: 4, reps: 10, musculo: "Cuádriceps"),
            EjercicioMock(nombre: "Prensa de piernas", series: 4, reps: 10, musculo: "Cuádriceps"),
            EjercicioMock(nombre: "Curl femoral tumbado", series: 3, reps: 12, musculo: "Femoral"),
            EjercicioMock(nombre: "Hip thrust", series: 3, reps: 12, musculo: "Glúteo"),
        ]),
    ]

    var body: some View {
        VStack(spacing: 0) {
            ModoEntrenadorHeader(paso: 4, onBack: { dismiss() })

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "wand.and.stars")
                            .foregroundColor(ProgresaColor.accent)
                        Text("Generamos un programa de \(dias.count) días. Ajusta los detalles y se guardará en tus rutinas.")
                            .font(.subheadline)
                            .foregroundColor(ProgresaColor.primary)
                    }
                    .padding(14)
                    .background(ProgresaColor.accent.opacity(0.12))
                    .cornerRadius(14)

                    informacionBasica
                    diasYEjercicios
                }
                .padding(20)
                .padding(.bottom, 100)
            }
        }
        .background(ProgresaColor.background)
        .navigationBarHidden(true)
        .safeAreaInset(edge: .bottom) {
            Button {
                irAGuardada = true
            } label: {
                Text("Guardar rutina")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(ProgresaPrimaryButtonStyle())
            .padding(16)
            .background(ProgresaColor.surface)
        }
        .navigationDestination(isPresented: $irAGuardada) {
            RutinaGuardadaView(
                nombreRutina: nombreRutina,
                totalDias: dias.count,
                primerDia: dias.first?.nombre ?? ""
            )
        }
    }

    // MARK: - Información básica

    private var informacionBasica: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Información básica")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(ProgresaColor.primary)

            VStack(alignment: .leading, spacing: 6) {
                Text("Nombre de la rutina")
                    .font(.footnote)
                    .foregroundColor(ProgresaColor.textSecondary)
                TextField("Nombre de la rutina", text: $nombreRutina)
                    .textFieldStyle(ProgresaTextFieldStyle())
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Descripción")
                    .font(.footnote)
                    .foregroundColor(ProgresaColor.textSecondary)
                TextField("Objetivo, frecuencia semanal, notas...", text: $descripcion, axis: .vertical)
                    .lineLimit(3...5)
                    .textFieldStyle(ProgresaTextFieldStyle())
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Fecha inicio")
                        .font(.footnote)
                        .foregroundColor(ProgresaColor.textSecondary)
                    campoFecha($fechaInicio, deshabilitado: false)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Fecha fin")
                        .font(.footnote)
                        .foregroundColor(ProgresaColor.textSecondary)
                    campoFecha($fechaFin, deshabilitado: !tieneFechaFin)
                }
            }

            Toggle("Tiene fecha de fin", isOn: $tieneFechaFin)
                .tint(ProgresaColor.primary)
                .foregroundColor(ProgresaColor.primary)

            VStack(alignment: .leading, spacing: 4) {
                Toggle("Marcar como rutina activa", isOn: $esActiva)
                    .tint(ProgresaColor.primary)
                    .foregroundColor(ProgresaColor.primary)
                Text("La rutina activa se muestra en Home como \"rutina de hoy\".")
                    .font(.caption)
                    .foregroundColor(ProgresaColor.textSecondary)
            }
        }
    }

    private func campoFecha(_ fecha: Binding<Date>, deshabilitado: Bool) -> some View {
        DatePicker("", selection: fecha, displayedComponents: .date)
            .labelsHidden()
            .datePickerStyle(.compact)
            .padding(10)
            .background(ProgresaColor.surface)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(ProgresaColor.border, lineWidth: 1))
            .cornerRadius(10)
            .opacity(deshabilitado ? 0.4 : 1)
            .disabled(deshabilitado)
    }

    // MARK: - Días y ejercicios
    // Estructura inspirada en EstructuraRutinaView.DiaRow (nombre del día +
    // conteo de ejercicios), extendida con expandir/colapsar in-line en
    // vez de navegar a un editor real.

    private var diasYEjercicios: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "checklist")
                Text("Días y ejercicios")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(ProgresaColor.primary)

            VStack(spacing: 10) {
                ForEach($dias) { $dia in
                    diaCard($dia)
                }
            }
        }
    }

    @ViewBuilder
    private func diaCard(_ dia: Binding<DiaMock>) -> some View {
        VStack(spacing: 0) {
            Button {
                withAnimation {
                    diaExpandido = (diaExpandido == dia.wrappedValue.id) ? nil : dia.wrappedValue.id
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(dia.wrappedValue.nombre)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(ProgresaColor.primary)
                        Text("\(dia.wrappedValue.ejercicios.count) ejercicios · \(dia.wrappedValue.musculos)")
                            .font(.footnote)
                            .foregroundColor(ProgresaColor.textSecondary)
                    }
                    Spacer()
                    Image(systemName: diaExpandido == dia.wrappedValue.id ? "chevron.up" : "chevron.down")
                        .foregroundColor(ProgresaColor.textSecondary)
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            if diaExpandido == dia.wrappedValue.id {
                VStack(spacing: 10) {
                    ForEach(Array(dia.wrappedValue.ejercicios.enumerated()), id: \.element.id) { index, ejercicio in
                        EjercicioMockRow(
                            ejercicio: ejercicio,
                            puedeSubir: index > 0,
                            puedeBajar: index < dia.wrappedValue.ejercicios.count - 1,
                            onSubir: { mover(dia, index, -1) },
                            onBajar: { mover(dia, index, 1) },
                            onSustituir: {
                                // TODO: sustitución real — sin funcionalidad todavía.
                            },
                            onEliminar: { dia.wrappedValue.ejercicios.remove(at: index) }
                        )
                    }

                    Button {
                        // TODO: agregar ejercicio del catálogo — sin funcionalidad todavía.
                    } label: {
                        Label("Agregar ejercicio", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(ProgresaOutlineButtonStyle())
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            }
        }
        .background(ProgresaColor.surface)
        .cornerRadius(16)
    }

    private func mover(_ dia: Binding<DiaMock>, _ index: Int, _ delta: Int) {
        let nuevoIndice = index + delta
        guard dia.wrappedValue.ejercicios.indices.contains(nuevoIndice) else { return }
        dia.wrappedValue.ejercicios.swapAt(index, nuevoIndice)
    }
}

#Preview {
    NavigationStack {
        ProgramaVariosDiasView()
    }
}
