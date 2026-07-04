import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text("Recuperar contraseña")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(ProgresaColor.primary)
                    Text("Te enviaremos un correo con instrucciones.")
                        .font(.subheadline)
                        .foregroundColor(ProgresaColor.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)

                TextField("Correo electrónico", text: $viewModel.email)
                    .textFieldStyle(ProgresaTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if let info = viewModel.infoMessage {
                    Text(info)
                        .font(.footnote)
                        .foregroundColor(ProgresaColor.accent)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    Task { await viewModel.resetPassword() }
                } label: {
                    if viewModel.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Enviar instrucciones")
                    }
                }
                .buttonStyle(ProgresaPrimaryButtonStyle(isLoading: viewModel.isLoading))
                .disabled(viewModel.isLoading)

                Spacer()
            }
            .padding(.horizontal, 24)
            .background(ProgresaColor.background)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                        .foregroundColor(ProgresaColor.primary)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    ForgotPasswordView()
        .environmentObject(AuthViewModel())
}
