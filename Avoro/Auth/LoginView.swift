import SwiftUI

struct LoginView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var showRegister = false
    @State private var showForgotPassword = false
    @State private var mostrarFormulario = false
    @State private var mostrarContrasena = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                logoPlaceholder
                    .padding(.top, 20)

                Spacer(minLength: 24)

                VStack(alignment: .leading, spacing: 12) {
                    (
                        Text("Tu progreso\n").foregroundColor(.white)
                        + Text("empieza aquí.").foregroundColor(ProgresaColor.accent)
                    )
                    .font(.system(size: 34, weight: .heavy))

                    Text("Entra para seguir sumando kilos y repeticiones.")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer(minLength: 32).fixedSize()

                if mostrarFormulario {
                    formularioCorreo
                } else {
                    botonesBienvenida
                }

                footerRegistro
                    .padding(.top, 20)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(ProgresaColor.primary.ignoresSafeArea())
            .navigationDestination(isPresented: $showRegister) {
                RegisterView()
            }
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView()
                    .environmentObject(viewModel)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Logo

    private var logoPlaceholder: some View {
        Image("LogoAvoro")
            .resizable()
            .scaledToFit()
            .frame(width: 96, height: 96)
    }

    // MARK: - Paso 1: bienvenida (correo / Google)

    private var botonesBienvenida: some View {
        VStack(spacing: 14) {
            Button {
                withAnimation { mostrarFormulario = true }
            } label: {
                HStack {
                    Image(systemName: "envelope.fill")
                    Text("Continuar con correo")
                }
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(ProgresaColor.accent)
                .cornerRadius(14)
            }

            Button {
                // TODO: Sign in with Google — sin funcionalidad todavía.
                // Cuando se implemente, usar el botón/asset oficial de
                // Google en vez de este placeholder de texto.
            } label: {
                HStack {
                    Text("G")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundColor(ProgresaColor.accent)
                    Text("Continuar con Google")
                }
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Paso 2: formulario de correo/contraseña

    private var formularioCorreo: some View {
        VStack(alignment: .leading, spacing: 18) {
            Button {
                withAnimation { mostrarFormulario = false }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text("Volver")
                }
                .foregroundColor(.white.opacity(0.8))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.8))

                TextField(
                    "",
                    text: $viewModel.email,
                    prompt: Text("tu-correo@mail.com").foregroundColor(.white.opacity(0.2))
                )
                .textFieldStyle(ProgresaDarkTextFieldStyle())
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Contraseña")
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.8))

                HStack {
                    Group {
                        if mostrarContrasena {
                            TextField("", text: $viewModel.password)
                        } else {
                            SecureField("", text: $viewModel.password)
                        }
                    }
                    .foregroundColor(.white)

                    Button {
                        mostrarContrasena.toggle()
                    } label: {
                        Image(systemName: mostrarContrasena ? "eye.slash" : "eye")
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(14)
                .background(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .cornerRadius(12)

                HStack {
                    Spacer()
                    Button("Olvidé mi contraseña") {
                        showForgotPassword = true
                    }
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.8))
                }
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundColor(Color.red.opacity(0.9))
            }
            if let info = viewModel.infoMessage {
                Text(info)
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.8))
            }

            Button {
                Task { await viewModel.signIn() }
            } label: {
                HStack {
                    if viewModel.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Iniciar sesión")
                        Image(systemName: "arrow.right")
                    }
                }
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(ProgresaColor.accent)
                .cornerRadius(14)
            }
            .disabled(viewModel.isLoading)
        }
    }

    // MARK: - Footer

    private var footerRegistro: some View {
        HStack(spacing: 4) {
            Text("¿No tienes cuenta?")
                .foregroundColor(.white.opacity(0.7))
            Button("Regístrate") {
                showRegister = true
            }
            .foregroundColor(.white)
            .fontWeight(.bold)
        }
        .font(.footnote)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

/// Campo de texto oscuro, específico de esta pantalla (LoginView es la
/// única con fondo navy completo; el resto de la app usa
/// ProgresaTextFieldStyle claro).
private struct ProgresaDarkTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .foregroundColor(.white)
            .padding(14)
            .background(Color.white.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .cornerRadius(12)
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
