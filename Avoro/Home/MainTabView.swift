import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Inicio", systemImage: "house.fill")
            }

            NavigationStack {
                // TODO: reemplazar por RutinaListView (Épica 2)
                Text("Listado de rutinas")
                    .navigationTitle("Rutinas")
            }
            .tabItem {
                Label("Rutinas", systemImage: "dumbbell.fill")
            }

            NavigationStack {
                PerfilPlaceholderView()
            }
            .tabItem {
                Label("Perfil", systemImage: "person.fill")
            }
        }
        .tint(ProgresaColor.primary)
    }
}

/// Placeholder temporal solo para poder probar signOut mientras
/// construimos la pantalla de Perfil real (Épica 8).
private struct PerfilPlaceholderView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 16) {
            Text("Perfil — pantalla pendiente")
                .foregroundColor(ProgresaColor.textSecondary)

            Button("Cerrar sesión") {
                Task { await authViewModel.signOut() }
            }
            .buttonStyle(ProgresaPrimaryButtonStyle())
            .padding(.horizontal, 40)
        }
        .navigationTitle("Perfil")
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
}
