import SwiftUI

struct EditarEquipoView: View {
    @StateObject private var viewModel: EditarEquipoViewModel
    @Environment(\.dismiss) private var dismiss
    let onGuardado: () -> Void

    init(usuarioId: UUID, onGuardado: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: EditarEquipoViewModel(usuarioId: usuarioId))
        self.onGuardado = onGuardado
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            if viewModel.isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        buscador

                        EquipoSeleccionGrid(
                            categorias: viewModel.categorias,
                            equipoPorCategoria: viewModel.equipoEnCategoria,
                            estaSeleccionado: { viewModel.seleccionados.contains($0.id) },
                            onToggle: { viewModel.toggle($0) }
                        )
                    }
                    .padding(20)
                }
            }

            footer
        }
        .background(ProgresaColor.background)
        .navigationBarHidden(true)
        .task {
            await viewModel.cargar()
        }
        .onChange(of: viewModel.guardadoConExito) { exito in
            guard exito else { return }
            onGuardado()
            dismiss()
        }
    }

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(ProgresaColor.primary)
            }
            Spacer()
            Text("¿Qué equipo tienes?")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(ProgresaColor.primary)
            Spacer()
            // Espaciador simétrico para centrar el título con el chevron.
            Image(systemName: "chevron.left").opacity(0)
        }
        .padding(16)
    }

    private var buscador: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(ProgresaColor.textSecondary)
            TextField("Buscar equipo...", text: $viewModel.busqueda)
        }
        .padding(12)
        .background(ProgresaColor.surface)
        .cornerRadius(12)
    }

    private var footer: some View {
        VStack(spacing: 10) {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundColor(.red)
            }

            Text("\(viewModel.seleccionados.count) seleccionados")
                .font(.footnote)
                .foregroundColor(ProgresaColor.textSecondary)

            Button {
                Task { await viewModel.guardar() }
            } label: {
                if viewModel.isSaving {
                    ProgressView().tint(.white)
                } else {
                    Text("Guardar")
                }
            }
            .buttonStyle(ProgresaPrimaryButtonStyle())
            .disabled(viewModel.isSaving)
        }
        .padding(16)
        .background(ProgresaColor.surface)
    }
}
