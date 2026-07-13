import SwiftUI

struct RutinaEditorView: View {
    @StateObject private var viewModel: RutinaEditorViewModel
    @Environment(\.dismiss) private var dismiss
    let onSaved: () -> Void
    let rutinaExistente: Rutina?

    @State private var rutinaParaEstructura: Rutina?
    @State private var mostrarEstructura = false

    private let opcionesCicloRapidas = [7, 14, 21, 28]

    init(rutinaExistente: Rutina?, onSaved: @escaping () -> Void) {
        self.rutinaExistente = rutinaExistente
        _viewModel = StateObject(wrappedValue: RutinaEditorViewModel(rutinaExistente: rutinaExistente))
        self.onSaved = onSaved
    }

    var body: some View {
        Form {
            Section("Información básica") {
                TextField("Nombre de la rutina", text: $viewModel.nombre)
                TextField("Descripción (opcional)", text: $viewModel.descripcion, axis: .vertical)
                    .lineLimit(2...4)
            }

            Section("Fechas") {
                DatePicker("Inicio", selection: $viewModel.fechaInicio, displayedComponents: .date)

                Toggle("Tiene fecha de fin", isOn: $viewModel.tieneFechaFin.animation())
                if viewModel.tieneFechaFin {
                    DatePicker("Fin", selection: $viewModel.fechaFin, in: viewModel.fechaInicio..., displayedComponents: .date)
                }
            }

            Section {
                Stepper(
                    "Se repite cada \(viewModel.cicloDias) día\(viewModel.cicloDias == 1 ? "" : "s")",
                    value: $viewModel.cicloDias,
                    in: 1...60
                )

                HStack(spacing: 8) {
                    ForEach(opcionesCicloRapidas, id: \.self) { opcion in
                        Button {
                            viewModel.cicloDias = opcion
                        } label: {
                            Text("\(opcion)")
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(viewModel.cicloDias == opcion ? ProgresaColor.primary : ProgresaColor.textSecondary)
                    }
                }
            } header: {
                Text("Duración del ciclo")
            } footer: {
                Text("El primer día que agregues siempre cae en \(fechaInicioFormateada). Si agregas menos días de entrenamiento que la duración del ciclo, los días restantes se muestran como descanso en Home. Ej.: 4 días de entrenamiento con un ciclo de 7 = 3 días de descanso por semana.")
            }

            Section {
                Toggle("Marcar como rutina activa", isOn: $viewModel.activa)
            } footer: {
                Text("La rutina activa es la que se muestra en Home como \"rutina de hoy\".")
            }

            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.footnote)
                }
            }

            if let existente = rutinaExistente {
                Section {
                    Button {
                        rutinaParaEstructura = existente
                        mostrarEstructura = true
                    } label: {
                        Label("Editar días y ejercicios", systemImage: "list.bullet.rectangle")
                    }
                }
            }
        }
        .navigationTitle(viewModel.tituloPantalla)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    Button("Guardar") {
                        Task { await guardar() }
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .navigationDestination(isPresented: $mostrarEstructura) {
            if let rutina = rutinaParaEstructura {
                EstructuraRutinaView(rutina: rutina)
            }
        }
    }

    private var fechaInicioFormateada: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_MX")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: viewModel.fechaInicio).capitalized(with: Locale(identifier: "es_MX"))
    }

    private func guardar() async {
        guard let resultado = await viewModel.guardar() else { return }
        onSaved()

        if viewModel.esEdicion {
            dismiss()
        } else {
            // Rutina recién creada: llevamos al usuario directo a construir
            // sus días y ejercicios, en vez de dejarlo en una rutina vacía.
            rutinaParaEstructura = resultado
            mostrarEstructura = true
        }
    }
}

#Preview {
    NavigationStack {
        RutinaEditorView(rutinaExistente: nil) {}
    }
}
