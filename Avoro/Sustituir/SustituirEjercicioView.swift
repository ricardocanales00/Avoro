import SwiftUI

struct SustituirEjercicioView: View {
    @StateObject private var viewModel: SustituirEjercicioViewModel
    @Environment(\.dismiss) private var dismiss

    /// Se llama cuando el usuario confirma una sustitución, con el ejercicio
    /// ya aplicado en la BD. Quien presente esta vista es responsable de
    /// actualizar su propio estado local (ver EjecucionRutinaView) y cerrar.
    let onSustituido: (EjercicioResumen) -> Void

    init(
        ejercicioDiaId: UUID,
        ejercicioOriginal: EjercicioResumen,
        usuarioId: UUID,
        onSustituido: @escaping (EjercicioResumen) -> Void
    ) {
        _viewModel = StateObject(wrappedValue: SustituirEjercicioViewModel(
            ejercicioDiaId: ejercicioDiaId,
            ejercicioOriginal: ejercicioOriginal,
            usuarioId: usuarioId
        ))
        self.onSustituido = onSustituido
    }

    var body: some View {
        VStack(spacing: 0) {
            headerNavegacion
            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(viewModel.mensajes) { mensaje in
                            burbuja(mensaje)
                                .id(mensaje.id)
                        }

                        if viewModel.isLoading {
                            typingIndicator
                        }

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.footnote)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(16)
                }
                .onChange(of: viewModel.mensajes.count) { _ in
                    guard let ultimo = viewModel.mensajes.last else { return }
                    withAnimation {
                        proxy.scrollTo(ultimo.id, anchor: .bottom)
                    }
                }
            }

            Divider()
            inputBar
        }
        .background(ProgresaColor.background)
        .navigationBarHidden(true)
        .task {
            await viewModel.iniciarConversacion()
        }
        .onChange(of: viewModel.ejercicioSustituto?.id) { _ in
            guard let nuevo = viewModel.ejercicioSustituto else { return }
            onSustituido(nuevo)
            dismiss()
        }
    }

    // MARK: - Header

    private var headerNavegacion: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(ProgresaColor.primary)
            }

            Text("Sustituir ejercicio")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(ProgresaColor.primary)

            Spacer()
        }
        .padding(16)
    }

    // MARK: - Burbujas de chat

    @ViewBuilder
    private func burbuja(_ mensaje: MensajeChatSustitucion) -> some View {
        switch mensaje.rol {
        case .asistente:
            HStack(alignment: .top, spacing: 10) {
                avatarAsistente
                VStack(alignment: .leading, spacing: 12) {
                    if !mensaje.texto.isEmpty {
                        Text(mensaje.texto)
                            .font(.subheadline)
                            .foregroundColor(ProgresaColor.primary)
                            .padding(12)
                            .background(ProgresaColor.surface)
                            .cornerRadius(16)
                    }

                    ForEach(mensaje.sugerencias) { sugerencia in
                        TarjetaSugerencia(sugerencia: sugerencia) {
                            Task { await viewModel.confirmarSustitucion(sugerencia) }
                        }
                    }
                }
                Spacer(minLength: 24)
            }

        case .usuario:
            HStack {
                Spacer(minLength: 24)
                Text(mensaje.texto)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(ProgresaColor.primary)
                    .cornerRadius(16)
            }
        }
    }

    private var avatarAsistente: some View {
        ZStack {
            Circle().fill(ProgresaColor.primary)
            Image(systemName: "sparkles")
                .font(.caption)
                .foregroundColor(.white)
        }
        .frame(width: 32, height: 32)
    }

    private var typingIndicator: some View {
        HStack(alignment: .top, spacing: 10) {
            avatarAsistente
            HStack(spacing: 6) {
                ProgressView().scaleEffect(0.7)
                Text("Pensando...")
                    .font(.footnote)
                    .foregroundColor(ProgresaColor.textSecondary)
            }
            .padding(12)
            .background(ProgresaColor.surface)
            .cornerRadius(16)
            Spacer()
        }
    }

    // MARK: - Input

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Escribe un mensaje...", text: $viewModel.textoInput)
                .textFieldStyle(ProgresaTextFieldStyle())
                .disabled(viewModel.isLoading)

            Button {
                Task { await viewModel.enviarMensaje() }
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(
                        viewModel.textoInput.trimmingCharacters(in: .whitespaces).isEmpty
                            ? ProgresaColor.textSecondary.opacity(0.4)
                            : ProgresaColor.primary
                    )
                    .clipShape(Circle())
            }
            .disabled(viewModel.textoInput.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLoading)
        }
        .padding(16)
    }
}

// MARK: - Tarjeta de sugerencia individual

private struct TarjetaSugerencia: View {
    let sugerencia: SugerenciaEjercicio
    let onUsar: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                imagen
                    .frame(width: 44, height: 44)
                    .background(ProgresaColor.border)
                    .cornerRadius(10)
                    .clipped()

                VStack(alignment: .leading, spacing: 2) {
                    Text("RECOMENDADO")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                    Text(sugerencia.ejercicio.nombre)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(ProgresaColor.primary)
                    Text("\(sugerencia.ejercicio.grupoMuscular.capitalized) · \(sugerencia.ejercicio.equipo?.nombre ?? "—")")
                        .font(.caption)
                        .foregroundColor(ProgresaColor.textSecondary)
                }
                Spacer()
            }
            .padding(12)

            Divider()

            Button(action: onUsar) {
                HStack {
                    Image(systemName: "checkmark")
                    Text("Usar este ejercicio")
                    Spacer()
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(ProgresaColor.primary)
                .padding(12)
            }
        }
        .background(ProgresaColor.surface)
        .cornerRadius(16)
        .frame(maxWidth: 280)
    }

    @ViewBuilder
    private var imagen: some View {
        if let urlString = sugerencia.ejercicio.imagenUrl, let url = URL(string: urlString) {
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
