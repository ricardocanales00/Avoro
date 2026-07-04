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
                // TODO: reemplazar por HomeView una vez exista.
                // Aquí también es donde, la primera vez que un usuario
                // entra tras registrarse, deberías verificar si ya
                // seleccionó su equipo disponible (tabla usuario_equipo)
                // y mandarlo a esa pantalla si no lo ha hecho.
                Text("Sesión iniciada ✅")
            }
        }
        .environmentObject(authViewModel)
    }
}

#Preview {
    AuthContainerView()
}
