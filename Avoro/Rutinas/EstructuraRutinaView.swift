import SwiftUI

struct EstructuraRutinaView: View {
    @StateObject private var viewModel: EstructuraRutinaViewModel
    let rutina: Rutina

    @State private var mostrarAgregarDia = false
    @State private var nombreNuevoDia = ""
    @State private var diaAEliminar: DiaConEjercicios?

    init(rutina: Rutina) {
        self.rutina = rutina
        _viewModel = StateObject(wrappedValue: EstructuraRutinaViewModel(rutina: rutina))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.dias.isEmpty {
                ProgressView()
            } else if viewModel.dias.isEmpty {
                estadoVacio
            } else {
                lista
            }
        }
        .navigationTitle(rutina.nombre)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    nombreNuevoDia = ""
                    mostrarAgregarDia = true
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(viewModel.dias.count >= viewModel.cicloDias)
            }
        }
        .task {
            await viewModel.cargarDias()
        }
        .alert("Nuevo día", isPresented: $mostrarAgregarDia) {
            TextField("Ej. Día 1 - Pecho y tríceps", text: $nombreNuevoDia)
            Button("Cancelar", role: .cancel) {}
            Button("Agregar") {
                Task { await viewModel.agregarDia(nombre: nombreNuevoDia) }
            }
        }
        .alert("¿Eliminar este día?", isPresented: Binding(
            get: { diaAEliminar != nil },
            set: { if !$0 { diaAEliminar = nil } }
        )) {
            Button("Cancelar", role: .cancel) { diaAEliminar = nil }
            Button("Eliminar", role: .destructive) {
                if let dia = diaAEliminar {
                    Task { await viewModel.eliminarDia(dia) }
                }
                diaAEliminar = nil
            }
        } message: {
            Text("Se eliminarán también los ejercicios asignados a este día.")
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

    private var resumenCiclo: some View {
        let descanso = viewModel.cicloDias - viewModel.dias.count
        return Text("Ciclo de \(viewModel.cicloDias) días · \(viewModel.dias.count) de entrenamiento · \(descanso) de descanso")
            .font(.footnote)
            .foregroundColor(ProgresaColor.textSecondary)
    }

    private var lista: some View {
        List {
            Section {
                ForEach(viewModel.dias.sorted { $0.orden < $1.orden }) { dia in
                    NavigationLink {
                        DiaEditorView(dia: dia, rutinaId: rutina.id) {
                            Task { await viewModel.cargarDias() }
                        }
                    } label: {
                        DiaRow(dia: dia)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            diaAEliminar = dia
                        } label: {
                            Label("Eliminar", systemImage: "trash")
                        }
                    }
                }
                .onMove(perform: viewModel.moverDias)
            } header: {
                resumenCiclo
                    .textCase(nil)
            } footer: {
                Text("Mantén presionado y arrastra para reordenar los días.")
            }
        }
        .listStyle(.plain)
        .toolbar { EditButton() }
    }

    private var estadoVacio: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(ProgresaColor.textSecondary)
            Text("Esta rutina aún no tiene días")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(ProgresaColor.primary)
            Text("Agrega tu primer día para empezar a asignar ejercicios.")
                .font(.subheadline)
                .foregroundColor(ProgresaColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            resumenCiclo
            Button("Agregar día") {
                nombreNuevoDia = ""
                mostrarAgregarDia = true
            }
            .buttonStyle(ProgresaPrimaryButtonStyle())
            .padding(.horizontal, 60)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ProgresaColor.background)
    }
}

private struct DiaRow: View {
    let dia: DiaConEjercicios

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(dia.nombreDia)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(ProgresaColor.primary)
            Text("\(dia.ejercicios.count) ejercicio\(dia.ejercicios.count == 1 ? "" : "s")")
                .font(.footnote)
                .foregroundColor(ProgresaColor.textSecondary)
        }
        .padding(.vertical, 4)
    }
}
