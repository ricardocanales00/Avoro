import SwiftUI

/// Punto de entrada de la app. Colócalo como la vista raíz en tu
/// ProgresaApp.swift (dentro de WindowGroup).
struct AuthContainerView: View {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some View {
        Group {
            switch authViewModel.authState {
            case .loading:
                ProgressView()
            case .signedOut:
                LoginView()
            case .signedIn:
                contenidoSignedIn
            }
        }
        .environmentObject(authViewModel)
    }

    /// Una vez hay sesión, todavía falta saber si el usuario ya completó
    /// el onboarding (`perfiles.onboarding_completado`) — mientras se
    /// revisa (`nil`), se muestra un loader en vez de parpadear entre
    /// wizard y app normal.
    @ViewBuilder
    private var contenidoSignedIn: some View {
        switch authViewModel.necesitaOnboarding {
        case .none:
            ProgressView()
        case .some(true):
            OnboardingWizardView {
                // El wizard ya marcó onboarding_completado = true en la
                // base de datos; actualizamos el flag local de inmediato
                // para no tener que volver a consultar Supabase.
                authViewModel.necesitaOnboarding = false
            }
        case .some(false):
            MainTabView()
        }
    }
}

#Preview {
    AuthContainerView()
}
