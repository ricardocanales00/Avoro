import SwiftUI

struct EditarEjerciciosView: View {
    @StateObject private var viewModel: EditarEjerciciosViewModel
    @Environment(\.dismiss) private var dismiss
    let onGuardado: () -> Void

    init(usuarioId: UUID, onGuardado: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: EditarEjerciciosViewModel(usuarioId: usuarioId))
        self.onGuardado = onGuardado
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            if viewModel.isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.sinEquipoConfigurado {
                estadoSinEquipo
            } else {
                buscador
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        ForEach(viewModel.gruposMusculares, id: \.self) { grupo in
                            seccionGrupo(grupo)
                        }
                    }
                    .padding(20)
                }

                footer
            }
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
            Text("Mis ejercicios")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(ProgresaColor.primary)
            Spacer()
            Image(systemName: "chevron.left").opacity(0)
        }
        .padding(16)
    }

    private var buscador: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(ProgresaColor.textSecondary)
            TextField("Buscar por nombre o músculo...", text: $viewModel.busqueda)
        }
        .padding(12)
        .background(ProgresaColor.surface)
        .cornerRadius(12)
    }

    private var estadoSinEquipo: some View {
        VStack(spacing: 12) {
            Image(systemName: "dumbbell")
                .font(.system(size: 40))
                .foregroundColor(ProgresaColor.textSecondary)
            Text("Todavía no tienes equipo configurado")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(ProgresaColor.primary)
            Text("Primero elige el equipo que tienes disponible; después podrás elegir qué ejercicios hacer con él.")
                .font(.subheadline)
                .foregroundColor(ProgresaColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func seccionGrupo(_ grupo: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(grupo.capitalized)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(ProgresaColor.primary)

            VStack(spacing: 8) {
                ForEach(viewModel.ejerciciosEnGrupo(grupo)) { ejercicio in
                    filaEjercicio(ejercicio)
                }
            }
        }
    }

    private func filaEjercicio(_ ejercicio: EjercicioResumen) -> some View {
        let seleccionado = viewModel.seleccionados.contains(ejercicio.id)
        return Button {
            viewModel.toggle(ejercicio)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(ejercicio.nombre)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(ProgresaColor.primary)
                    if let equipo = ejercicio.equipo?.nombre {
                        Text(equipo)
                            .font(.caption)
                            .foregroundColor(ProgresaColor.textSecondary)
                    }
                }
                Spacer()
                Image(systemName: seleccionado ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(seleccionado ? ProgresaColor.accent : ProgresaColor.border)
                    .font(.title3)
            }
            .padding(14)
            .background(ProgresaColor.surface)
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }

    private var footer: some View {
        VStack(spacing: 10) {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundColor(.red)
            }

            Text("\(viewModel.seleccionados.count) ejercicios habilitados")
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
