import SwiftUI

struct RutinaEditorView: View {
    @StateObject private var viewModel: RutinaEditorViewModel
    @Environment(\.dismiss) private var dismiss
    let onSaved: () -> Void
    let rutinaExistente: Rutina?

    @State private var rutinaParaEstructura: Rutina?
    @State private var mostrarEstructura = false

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
