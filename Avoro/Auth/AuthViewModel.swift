import Foundation
import Supabase
import Combine

enum AuthState {
    case loading
    case signedOut
    case signedIn
}

@MainActor
final class AuthViewModel: ObservableObject {
    // Campos de formulario
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var nombre = ""

    // Estado de UI
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var infoMessage: String?
    @Published var authState: AuthState = .loading

    private let client = SupabaseService.shared.client

    init() {
        Task { await observeAuthChanges() }
    }

    /// Escucha cambios de sesión (login, logout, refresh de token, etc.)
    /// para que la app reaccione automáticamente sin polling manual.
    private func observeAuthChanges() async {
        for await state in client.auth.authStateChanges {
            switch state.event {
            case .initialSession, .signedIn, .tokenRefreshed:
                authState = client.auth.currentSession != nil ? .signedIn : .signedOut
            case .signedOut:
                authState = .signedOut
            default:
                break
            }
        }
    }

    func signIn() async {
        clearMessages()
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Ingresa correo y contraseña."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await client.auth.signIn(email: email, password: password)
        } catch {
            errorMessage = mensajeAmigable(para: error)
        }
    }

    func signUp() async {
        clearMessages()
        guard validateSignUpFields() else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            try await client.auth.signUp(
                email: email,
                password: password,
                data: ["nombre": .string(nombre)]
            )
            // El trigger on_auth_user_created crea el perfil automáticamente
            // en public.perfiles con este nombre.
            //
            // Si tienes activada la confirmación de correo en Supabase Auth,
            // aquí NO quedará una sesión iniciada de inmediato.
            if client.auth.currentSession == nil {
                infoMessage = "Te enviamos un correo para confirmar tu cuenta. Confírmalo y luego inicia sesión."
            }
            // TODO siguiente pantalla: una vez confirmada la sesión, este es
            // el punto donde debe entrar el paso "Selección de equipo
            // disponible" (Épica 1) antes de mandar al usuario a Home.
        } catch {
            errorMessage = mensajeAmigable(para: error)
        }
    }

    func resetPassword() async {
        clearMessages()
        guard !email.isEmpty else {
            errorMessage = "Ingresa tu correo para recuperar tu contraseña."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await client.auth.resetPasswordForEmail(email)
            infoMessage = "Revisa tu correo, te enviamos instrucciones para recuperar tu contraseña."
        } catch {
            errorMessage = mensajeAmigable(para: error)
        }
    }

    func signOut() async {
        do {
            try await client.auth.signOut()
        } catch {
            errorMessage = mensajeAmigable(para: error)
        }
    }

    private func clearMessages() {
        errorMessage = nil
        infoMessage = nil
    }

    private func validateSignUpFields() -> Bool {
        guard !nombre.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Ingresa tu nombre."
            return false
        }
        guard email.contains("@"), email.contains(".") else {
            errorMessage = "Ingresa un correo válido."
            return false
        }
        guard password.count >= 6 else {
            errorMessage = "La contraseña debe tener al menos 6 caracteres."
            return false
        }
        guard password == confirmPassword else {
            errorMessage = "Las contraseñas no coinciden."
            return false
        }
        return true
    }

    /// Supabase regresa errores técnicos en inglés; los traducimos
    /// a mensajes simples para no exponer detalles internos.
    private func mensajeAmigable(para error: Error) -> String {
        let texto = error.localizedDescription.lowercased()
        if texto.contains("invalid login credentials") {
            return "Correo o contraseña incorrectos."
        } else if texto.contains("already registered") || texto.contains("already exists") {
            return "Ya existe una cuenta con ese correo."
        } else if texto.contains("password") {
            return "La contraseña no cumple los requisitos mínimos."
        } else if texto.contains("network") {
            return "Problema de conexión. Revisa tu internet e intenta de nuevo."
        }
        return "Ocurrió un error. Intenta de nuevo."
    }
}
