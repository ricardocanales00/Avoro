import SwiftUI

struct RutinaListView: View {
    @StateObject private var viewModel = RutinaListViewModel()
    @State private var mostrarCrear = false
    @State private var rutinaAEliminar: Rutina?

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.rutinas.isEmpty {
                ProgressView()
            } else if viewModel.rutinas.isEmpty {
                estadoVacio
            } else {
                lista
            }
        }
        .navigationTitle("Mis rutinas")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    mostrarCrear = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .navigationDestination(isPresented: $mostrarCrear) {
            RutinaEditorView(rutinaExistente: nil) {
                Task { await viewModel.cargarRutinas() }
            }
        }
        .task {
            await viewModel.cargarRutinas()
        }
        .refreshable {
            await viewModel.cargarRutinas()
        }
        .alert("¿Eliminar esta rutina?", isPresented: Binding(
            get: { rutinaAEliminar != nil },
            set: { if !$0 { rutinaAEliminar = nil } }
        )) {
            Button("Cancelar", role: .cancel) { rutinaAEliminar = nil }
            Button("Eliminar", role: .destructive) {
                if let rutina = rutinaAEliminar {
                    Task { await viewModel.eliminar(rutina) }
                }
                rutinaAEliminar = nil
            }
        } message: {
            Text("Se eliminarán también sus días, ejercicios y registros asociados. Esta acción no se puede deshacer.")
        }
    }

    private var lista: some View {
        List {
            ForEach(viewModel.rutinas) { rutina in
                NavigationLink {
                    RutinaEditorView(rutinaExistente: rutina) {
                        Task { await viewModel.cargarRutinas() }
                    }
                } label: {
                    RutinaRow(rutina: rutina)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        rutinaAEliminar = rutina
                    } label: {
                        Label("Eliminar", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    private var estadoVacio: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 40))
                .foregroundColor(ProgresaColor.textSecondary)
            Text("Aún no tienes rutinas")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(ProgresaColor.primary)
            Text("Crea tu primera rutina para empezar.")
                .font(.subheadline)
                .foregroundColor(ProgresaColor.textSecondary)
            Button("Crear rutina") {
                mostrarCrear = true
            }
            .buttonStyle(ProgresaPrimaryButtonStyle())
            .padding(.horizontal, 60)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ProgresaColor.background)
    }
}

private struct RutinaRow: View {
    let rutina: Rutina

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(rutina.nombre)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(ProgresaColor.primary)
                    if rutina.activa {
                        Text("Activa")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(ProgresaColor.accent.opacity(0.15))
                            .foregroundColor(ProgresaColor.accent)
                            .cornerRadius(6)
                    }
                }
                if let descripcion = rutina.descripcion, !descripcion.isEmpty {
                    Text(descripcion)
                        .font(.footnote)
                        .foregroundColor(ProgresaColor.textSecondary)
                        .lineLimit(1)
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        RutinaListView()
    }
}
