import SwiftUI

struct DiaEditorView: View {
    @StateObject private var viewModel: DiaEditorViewModel
    let dia: DiaConEjercicios
    let onCambio: () -> Void

    @State private var mostrarPicker = false
    @State private var ejercicioSeleccionado: EjercicioResumen?
    @State private var ejercicioAEditar: EjercicioDiaConEjercicio?
    @State private var ejercicioAEliminar: EjercicioDiaConEjercicio?

    init(dia: DiaConEjercicios, rutinaId: UUID, onCambio: @escaping () -> Void) {
        self.dia = dia
        self.onCambio = onCambio
        _viewModel = StateObject(wrappedValue: DiaEditorViewModel(dia: dia))
    }

    var body: some View {
        Group {
            if viewModel.ejercicios.isEmpty {
                estadoVacio
            } else {
                lista
            }
        }
        .navigationTitle(dia.nombreDia)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    mostrarPicker = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $mostrarPicker) {
            EjercicioPickerView { ejercicio in
                mostrarPicker = false
                ejercicioSeleccionado = ejercicio
            }
        }
        .sheet(item: $ejercicioSeleccionado) { ejercicio in
            SeriesRepsSheet(
                titulo: ejercicio.nombre,
                seriesInicial: 3,
                repeticionesInicial: 10
            ) { series, reps in
                Task {
                    await viewModel.agregarEjercicio(ejercicio, series: series, repeticiones: reps)
                    onCambio()
                }
            }
        }
        .sheet(item: $ejercicioAEditar) { item in
            SeriesRepsSheet(
                titulo: item.ejercicio.nombre,
                seriesInicial: item.seriesObjetivo,
                repeticionesInicial: item.repeticionesObjetivo
            ) { series, reps in
                Task {
                    await viewModel.actualizarSeriesReps(item, series: series, repeticiones: reps)
                    onCambio()
                }
            }
        }
        .alert("¿Quitar este ejercicio del día?", isPresented: Binding(
            get: { ejercicioAEliminar != nil },
            set: { if !$0 { ejercicioAEliminar = nil } }
        )) {
            Button("Cancelar", role: .cancel) { ejercicioAEliminar = nil }
            Button("Quitar", role: .destructive) {
                if let item = ejercicioAEliminar {
                    Task {
                        await viewModel.eliminar(item)
                        onCambio()
                    }
                }
                ejercicioAEliminar = nil
            }
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

    private var lista: some View {
        List {
            Section {
                ForEach(viewModel.ejercicios) { item in
                    Button {
                        ejercicioAEditar = item
                    } label: {
                        EjercicioDiaRow(item: item)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            ejercicioAEliminar = item
                        } label: {
                            Label("Quitar", systemImage: "trash")
                        }
                    }
                }
                .onMove(perform: viewModel.mover)
            } footer: {
                Text("Toca un ejercicio para editar sus series y repeticiones. Mantén presionado para reordenar.")
            }
        }
        .listStyle(.plain)
        .toolbar { EditButton() }
    }

    private var estadoVacio: some View {
        VStack(spacing: 12) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 40))
                .foregroundColor(ProgresaColor.textSecondary)
            Text("Este día aún no tiene ejercicios")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(ProgresaColor.primary)
            Button("Agregar ejercicio") {
                mostrarPicker = true
            }
            .buttonStyle(ProgresaPrimaryButtonStyle())
            .padding(.horizontal, 60)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ProgresaColor.background)
    }
}

private struct EjercicioDiaRow: View {
    let item: EjercicioDiaConEjercicio

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.ejercicio.nombre)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ProgresaColor.primary)
                Text(item.ejercicio.grupoMuscular.capitalized)
                    .font(.caption)
                    .foregroundColor(ProgresaColor.textSecondary)
            }
            Spacer()
            Text("\(item.seriesObjetivo) × \(item.repeticionesObjetivo)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(ProgresaColor.primary)
        }
        .padding(.vertical, 4)
    }
}

/// Sheet compacto para capturar series y repeticiones, tanto al agregar
/// un ejercicio nuevo como al editar uno existente.
private struct SeriesRepsSheet: View {
    let titulo: String
    @State var series: Int
    @State var repeticiones: Int
    let onConfirmar: (Int, Int) -> Void

    @Environment(\.dismiss) private var dismiss

    init(titulo: String, seriesInicial: Int, repeticionesInicial: Int, onConfirmar: @escaping (Int, Int) -> Void) {
        self.titulo = titulo
        self._series = State(initialValue: seriesInicial)
        self._repeticiones = State(initialValue: repeticionesInicial)
        self.onConfirmar = onConfirmar
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(titulo) {
                    Stepper("Series: \(series)", value: $series, in: 1...10)
                    Stepper("Repeticiones: \(repeticiones)", value: $repeticiones, in: 1...50)
                }
            }
            .navigationTitle("Series y repeticiones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {
                        onConfirmar(series, repeticiones)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
