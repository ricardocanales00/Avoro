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
                // TODO: aquí es donde, la primera vez que un usuario entra
                // tras registrarse, deberías verificar si ya seleccionó su
                // equipo disponible (tabla usuario_equipo) y mandarlo a esa
                // pantalla en vez de MainTabView si no lo ha hecho.
                MainTabView()
            }
        }
        .environmentObject(authViewModel)
    }
}

#Preview {
    AuthContainerView()
}
