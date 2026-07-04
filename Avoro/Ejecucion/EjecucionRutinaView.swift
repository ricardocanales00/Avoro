import SwiftUI

struct EjecucionRutinaView: View {
    @StateObject private var viewModel: EjecucionRutinaViewModel
    @Environment(\.dismiss) private var dismiss

    init(dia: DiaConEjercicios, unidadPreferida: String) {
        _viewModel = StateObject(wrappedValue: EjecucionRutinaViewModel(dia: dia, unidadPreferida: unidadPreferida))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                progresoHeader

                if viewModel.rutinaTerminada {
                    banderaCompletada
                }

                ForEach($viewModel.ejercicios) { $estado in
                    EjercicioEjecucionCard(
                        estado: $estado,
                        unidad: viewModel.unidadSeleccionada
                    ) {
                        Task { await viewModel.guardarSeries(paraEjercicioConId: estado.id) }
                    }
                }
            }
            .padding(20)
        }
        .background(ProgresaColor.background)
        .navigationTitle(viewModel.dia.nombreDia)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.cargarProgresoDeHoy()
        }
        .safeAreaInset(edge: .bottom) {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(ProgresaColor.surface)
            }
        }
    }

    private var progresoHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Progreso de hoy")
                    .font(.footnote)
                    .foregroundColor(ProgresaColor.textSecondary)
                Spacer()
                Picker("Unidad", selection: $viewModel.unidadSeleccionada) {
                    Text("kg").tag("kg")
                    Text("lb").tag("lb")
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
            }

            HStack(spacing: 10) {
                ProgressView(value: Double(viewModel.completados), total: Double(max(viewModel.total, 1)))
                    .tint(ProgresaColor.accent)
                Text("\(viewModel.completados)/\(viewModel.total)")
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundColor(ProgresaColor.accent)
            }
        }
    }

    private var banderaCompletada: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(ProgresaColor.accent)
            Text("¡Rutina completada! Buen trabajo.")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(ProgresaColor.primary)
            Spacer()
        }
        .padding(14)
        .background(ProgresaColor.accent.opacity(0.12))
        .cornerRadius(14)
    }
}

// MARK: - Card por ejercicio

private struct EjercicioEjecucionCard: View {
    @Binding var estado: EjercicioEjecucionState
    let unidad: String
    let onGuardar: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                imagen
                    .frame(width: 44, height: 44)
                    .background(ProgresaColor.border)
                    .cornerRadius(10)
                    .clipped()

                VStack(alignment: .leading, spacing: 2) {
                    Text(estado.ejercicioDia.ejercicio.nombre)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(ProgresaColor.primary)
                    Text(estado.ejercicioDia.ejercicio.grupoMuscular.capitalized)
                        .font(.caption)
                        .foregroundColor(ProgresaColor.textSecondary)
                }

                Spacer()

                if estado.completado {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(ProgresaColor.accent)
                        .font(.title3)
                }
            }

            if estado.completado {
                resumenGuardado
            } else {
                formularioSeries
            }
        }
        .padding(16)
        .background(ProgresaColor.surface)
        .cornerRadius(20)
    }

    private var formularioSeries: some View {
        VStack(spacing: 10) {
            ForEach($estado.series) { $serie in
                HStack(spacing: 8) {
                    Text("Serie \(serie.numeroSerie)")
                        .font(.footnote)
                        .foregroundColor(ProgresaColor.textSecondary)
                        .frame(width: 56, alignment: .leading)

                    TextField("Reps", text: $serie.repeticiones)
                        .keyboardType(.numberPad)
                        .textFieldStyle(ProgresaTextFieldStyle())

                    TextField("Peso (\(unidad))", text: $serie.peso)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(ProgresaTextFieldStyle())
                }
            }

            Button("Guardar serie\(estado.series.count == 1 ? "" : "s")") {
                onGuardar()
            }
            .buttonStyle(ProgresaPrimaryButtonStyle())
        }
    }

    private var resumenGuardado: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(estado.registrosGuardadosHoy.sorted { $0.numeroSerie < $1.numeroSerie }) { registro in
                Text("Serie \(registro.numeroSerie): \(registro.repeticionesReales) reps · \(formatearPeso(registro.peso)) \(registro.unidad)")
                    .font(.footnote)
                    .foregroundColor(ProgresaColor.textSecondary)
            }
        }
    }

    private func formatearPeso(_ peso: Double) -> String {
        peso.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", peso)
            : String(format: "%.1f", peso)
    }

    @ViewBuilder
    private var imagen: some View {
        if let urlString = estado.ejercicioDia.ejercicio.imagenUrl, let url = URL(string: urlString) {
            AsyncImage(url: url) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color(ProgresaColor.border)
            }
        } else {
            ZStack {
                Color(ProgresaColor.border)
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundColor(ProgresaColor.textSecondary)
            }
        }
    }
}
