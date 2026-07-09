import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 6) {
                    Text("Crea tu cuenta")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(ProgresaColor.primary)
                    Text("Podrás configurar tu equipo disponible después.")
                        .font(.subheadline)
                        .foregroundColor(ProgresaColor.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)

                VStack(spacing: 14) {
                    TextField("Nombre", text: $viewModel.nombre)
                        .textFieldStyle(ProgresaTextFieldStyle())
                        .textInputAutocapitalization(.words)

                    TextField("Correo electrónico", text: $viewModel.email)
                        .textFieldStyle(ProgresaTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    SecureField("Contraseña (mín. 6 caracteres)", text: $viewModel.password)
                        .textFieldStyle(ProgresaTextFieldStyle())

                    SecureField("Confirmar contraseña", text: $viewModel.confirmPassword)
                        .textFieldStyle(ProgresaTextFieldStyle())
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
                    Task { await viewModel.signUp() }
                } label: {
                    if viewModel.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Crear cuenta")
                    }
                }
                .buttonStyle(ProgresaPrimaryButtonStyle(isLoading: viewModel.isLoading))
                .disabled(viewModel.isLoading)
            }
            .padding(.horizontal, 24)
        }
        .background(ProgresaColor.background)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.light)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(ProgresaColor.primary)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        RegisterView()
            .environmentObject(AuthViewModel())
    }
}
