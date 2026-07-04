import SwiftUI

struct LoginView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var showRegister = false
    @State private var showForgotPassword = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 6) {
                        Text("Progresa")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(ProgresaColor.primary)
                        Text("Registra tu progreso, no solo tus repeticiones.")
                            .font(.subheadline)
                            .foregroundColor(ProgresaColor.textSecondary)
                    }
                    .padding(.top, 60)

                    VStack(spacing: 14) {
                        TextField("Correo electrónico", text: $viewModel.email)
                            .textFieldStyle(ProgresaTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        SecureField("Contraseña", text: $viewModel.password)
                            .textFieldStyle(ProgresaTextFieldStyle())

                        HStack {
                            Spacer()
                            Button("¿Olvidaste tu contraseña?") {
                                showForgotPassword = true
                            }
                            .font(.footnote)
                            .foregroundColor(ProgresaColor.primary)
                        }
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if let info = viewModel.infoMessage {
                        Text(info)
                            .font(.footnote)
                            .foregroundColor(ProgresaColor.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button {
                        Task { await viewModel.signIn() }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Iniciar sesión")
                        }
                    }
                    .buttonStyle(ProgresaPrimaryButtonStyle(isLoading: viewModel.isLoading))
                    .disabled(viewModel.isLoading)

                    HStack(spacing: 4) {
                        Text("¿No tienes cuenta?")
                            .foregroundColor(ProgresaColor.textSecondary)
                        Button("Regístrate") {
                            showRegister = true
                        }
                        .foregroundColor(ProgresaColor.primary)
                        .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                }
                .padding(.horizontal, 24)
            }
            .background(ProgresaColor.background)
            .navigationDestination(isPresented: $showRegister) {
                RegisterView()
            }
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView()
                    .environmentObject(viewModel)
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
