import SwiftUI

struct EjercicioPickerView: View {
    let onSeleccionar: (EjercicioResumen) -> Void

    @State private var catalogo: [EjercicioResumen] = []
    @State private var busqueda = ""
    @State private var isLoading = true
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    private let service = RutinaService()

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                } else if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    lista
                }
            }
            .navigationTitle("Elegir ejercicio")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $busqueda, prompt: "Buscar ejercicio")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .task {
                await cargarCatalogo()
            }
        }
    }

    private var ejerciciosFiltrados: [EjercicioResumen] {
        guard !busqueda.isEmpty else { return catalogo }
        return catalogo.filter { $0.nombre.localizedCaseInsensitiveContains(busqueda) }
    }

    private var gruposMusculares: [String] {
        Array(Set(ejerciciosFiltrados.map(\.grupoMuscular))).sorted()
    }

    private var lista: some View {
        List {
            ForEach(gruposMusculares, id: \.self) { grupo in
                Section(grupo.capitalized) {
                    ForEach(ejerciciosFiltrados.filter { $0.grupoMuscular == grupo }) { ejercicio in
                        Button {
                            onSeleccionar(ejercicio)
                        } label: {
                            Text(ejercicio.nombre)
                                .foregroundColor(ProgresaColor.primary)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func cargarCatalogo() async {
        isLoading = true
        errorMessage = nil
        do {
            catalogo = try await service.fetchCatalogoEjercicios()
        } catch {
            errorMessage = "No se pudo cargar el catálogo de ejercicios."
        }
        isLoading = false
    }
}

#Preview {
    EjercicioPickerView { _ in }
}
