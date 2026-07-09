import SwiftUI

/// Último paso del wizard. Reutiliza `EditarEquipoViewModel` tal cual (la
/// misma clase que usa la pantalla de Perfil para editar equipo después),
/// pero con su propio "chrome" de wizard: barra de progreso 6/6, botón
/// "Finalizar" en vez de "Guardar", y un botón para omitir este paso.
struct OnboardingEquipoStepView: View {
    @ObservedObject var onboardingViewModel: OnboardingViewModel
    @StateObject private var equipoViewModel: EditarEquipoViewModel
    let onFinalizado: () -> Void

    init(viewModel: OnboardingViewModel, onFinalizado: @escaping () -> Void) {
        self.onboardingViewModel = viewModel
        // Si no hay sesión (no debería pasar en este punto del flujo), el
        // ViewModel de equipo simplemente no tendrá nada que guardar —
        // `usuarioId` ya viene validado desde `guardarDatosBasicos()`.
        _equipoViewModel = StateObject(wrappedValue: EditarEquipoViewModel(usuarioId: viewModel.usuarioId ?? UUID()))
        self.onFinalizado = onFinalizado
    }

    var body: some View {
        VStack(spacing: 0) {
            OnboardingHeader(
                pasoActual: onboardingViewModel.pasoActual,
                totalPasos: onboardingViewModel.totalPasos,
                titulo: "¿Qué equipo tienes?",
                subtitulo: "Lo usamos para sugerir ejercicios que sí puedes hacer."
            )
            .padding(20)
            .padding(.bottom, 0)

            if equipoViewModel.isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        buscador

                        EquipoSeleccionGrid(
                            categorias: equipoViewModel.categorias,
                            equipoPorCategoria: equipoViewModel.equipoEnCategoria,
                            estaSeleccionado: { equipoViewModel.seleccionados.contains($0.id) },
                            onToggle: { equipoViewModel.toggle($0) }
                        )
                    }
                    .padding(20)
                }
            }

            footer
        }
        .background(ProgresaColor.background)
        .task {
            await equipoViewModel.cargar()
        }
        .onChange(of: equipoViewModel.guardadoConExito) { exito in
            guard exito else { return }
            Task { await onboardingViewModel.finalizarOnboarding() }
        }
    }

    private var buscador: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(ProgresaColor.textSecondary)
            TextField("Buscar equipo...", text: $equipoViewModel.busqueda)
        }
        .padding(12)
        .background(ProgresaColor.surface)
        .cornerRadius(12)
    }

    private var footer: some View {
        VStack(spacing: 10) {
            if let error = equipoViewModel.errorMessage ?? onboardingViewModel.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundColor(.red)
            }

            Text("\(equipoViewModel.seleccionados.count) seleccionados")
                .font(.footnote)
                .foregroundColor(ProgresaColor.textSecondary)

            Button {
                Task { await equipoViewModel.guardar() }
            } label: {
                if equipoViewModel.isSaving || onboardingViewModel.isSaving {
                    ProgressView().tint(.white)
                } else {
                    Text("Finalizar")
                }
            }
            .buttonStyle(ProgresaPrimaryButtonStyle())
            .disabled(equipoViewModel.isSaving || onboardingViewModel.isSaving)

            Button {
                Task { await onboardingViewModel.finalizarOnboarding() }
            } label: {
                Text("Agregar después")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(ProgresaColor.textSecondary)
            }
            .disabled(equipoViewModel.isSaving || onboardingViewModel.isSaving)

            Text("Los puedes agregar o modificar en tu perfil")
                .font(.caption2)
                .foregroundColor(ProgresaColor.textSecondary)
        }
        .padding(16)
        .background(ProgresaColor.surface)
    }
}
