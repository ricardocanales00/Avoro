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

    /// `nil` = todavía no se ha revisado (o no hay sesión); `true` = el
    /// usuario necesita pasar por el wizard; `false` = ya lo completó.
    /// `AuthContainerView` usa esto para decidir entre mostrar
    /// `OnboardingWizardView` o `MainTabView` una vez `authState == .signedIn`.
    @Published var necesitaOnboarding: Bool?

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
                let sesionActiva = client.auth.currentSession != nil
                authState = sesionActiva ? .signedIn : .signedOut

                if sesionActiva {
                    // Solo se revisa una vez por sesión (mientras
                    // `necesitaOnboarding` sea `nil`) — un `tokenRefreshed`
                    // no debería volver a disparar la consulta cada vez.
                    if necesitaOnboarding == nil {
                        await revisarOnboarding()
                    }
                } else {
                    necesitaOnboarding = nil
                }
            case .signedOut:
                authState = .signedOut
                necesitaOnboarding = nil
            default:
                break
            }
        }
    }

    /// Consulta `perfiles.onboarding_completado` para el usuario actual.
    private func revisarOnboarding() async {
        guard let usuarioId = client.auth.currentUser?.id else { return }

        do {
            let perfil: PerfilOnboardingCheck = try await client
                .from("perfiles")
                .select("onboarding_completado")
                .eq("id", value: usuarioId)
                .single()
                .execute()
                .value
            necesitaOnboarding = !perfil.onboardingCompletado
        } catch {
            // Si la consulta falla (red, RLS, lo que sea), preferimos NO
            // bloquear el acceso a la app con el wizard forzado — es mejor
            // que un usuario raro se salte el onboarding a que un error de
            // red deje a todos atorados sin poder entrar.
            necesitaOnboarding = false
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
            // en public.perfiles con este nombre (y onboarding_completado
            // queda en `false` por default — el listener de arriba se
            // encarga de mostrar el wizard en cuanto haya sesión activa).
            //
            // Si tienes activada la confirmación de correo en Supabase Auth,
            // aquí NO quedará una sesión iniciada de inmediato.
            if client.auth.currentSession == nil {
                infoMessage = "Te enviamos un correo para confirmar tu cuenta. Confírmalo y luego inicia sesión."
            }
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

/// Struct liviano solo para esta consulta puntual — no reemplaza tu
/// modelo `Perfil` completo, solo evita traer todas las columnas cuando
/// nada más se necesita saber si el onboarding ya se completó.
private struct PerfilOnboardingCheck: Decodable {
    let onboardingCompletado: Bool

    enum CodingKeys: String, CodingKey {
        case onboardingCompletado = "onboarding_completado"
    }
}
