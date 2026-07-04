import SwiftUI

struct MainTabView: View {

    @State private var selectedTab = 0

    var body: some View {

        TabView(selection: $selectedTab) {

            NavigationStack {
                HomeView(selectedTab: $selectedTab)
            }
            .tabItem {
                Label("Inicio", systemImage: "house.fill")
            }
            .tag(0)

            NavigationStack {
                Text("Listado de rutinas")
                    .navigationTitle("Rutinas")
            }
            .tabItem {
                Label("Rutinas", systemImage: "dumbbell.fill")
            }
            .tag(1)

            NavigationStack {
                PerfilPlaceholderView()
            }
            .tabItem {
                Label("Perfil", systemImage: "person.fill")
            }
            .tag(2)
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
