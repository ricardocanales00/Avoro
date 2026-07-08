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
                RutinaListView()
            }
            .tabItem {
                Label("Rutinas", systemImage: "dumbbell.fill")
            }
            .tag(1)

            NavigationStack {
                PerfilView()
            }
            .tabItem {
                Label("Perfil", systemImage: "person.fill")
            }
            .tag(2)
        }
        .tint(ProgresaColor.primary)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
}
