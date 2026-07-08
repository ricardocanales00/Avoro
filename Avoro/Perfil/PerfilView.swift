import SwiftUI
import Supabase

struct PerfilView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = PerfilViewModel()

    /// Se lee directo de Supabase Auth en vez de agregarlo a PerfilViewModel,
    /// para no tocar ese archivo — si prefieres centralizarlo ahí después,
    /// es mover una línea.
    @State private var mostrarEditarEquipo = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Perfil")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(ProgresaColor.primary)
                    .padding(.top, 12)

                perfilHeader

                preferenciasSection

                miEquipoSection

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(.red)
                }

                botonCerrarSesion
            }
            .padding(20)
        }
        .background(ProgresaColor.background)
        .task {
            await viewModel.cargar()
        }
        .navigationDestination(isPresented: $mostrarEditarEquipo) {
            if let usuarioId = SupabaseService.shared.client.auth.currentUser?.id {
                EditarEquipoView(usuarioId: usuarioId) {}
            }
        }
    }

    // MARK: - Header (avatar + nombre + email)

    private var perfilHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(ProgresaColor.primary)
                Text(viewModel.iniciales)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.nombre.isEmpty ? "..." : viewModel.nombre)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(ProgresaColor.primary)
                Text(viewModel.email)
                    .font(.subheadline)
                    .foregroundColor(ProgresaColor.textSecondary)
            }
        }
    }

    // MARK: - Preferencias (solo unidad de peso por ahora)

    private var preferenciasSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Preferencias")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(ProgresaColor.primary)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Unidad de peso")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(ProgresaColor.primary)
                    Text("Se usa en toda la app")
                        .font(.footnote)
                        .foregroundColor(ProgresaColor.textSecondary)
                }
                Spacer()
                unidadToggle
            }
            .padding(16)
            .background(ProgresaColor.surface)
            .cornerRadius(16)
        }
    }

    private var unidadToggle: some View {
        HStack(spacing: 0) {
            botonUnidad("kg")
            botonUnidad("lb")
        }
        .background(ProgresaColor.border.opacity(0.4))
        .cornerRadius(10)
    }

    private func botonUnidad(_ valor: String) -> some View {
        Button {
            Task { await viewModel.actualizarUnidad(valor) }
        } label: {
            Text(valor)
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundColor(viewModel.unidadPreferida == valor ? .white : ProgresaColor.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(viewModel.unidadPreferida == valor ? ProgresaColor.primary : Color.clear)
                .cornerRadius(8)
        }
    }

    // MARK: - Mi equipo disponible

    private var miEquipoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Mi equipo disponible")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(ProgresaColor.primary)

            Button {
                mostrarEditarEquipo = true
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Editar equipo disponible")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(ProgresaColor.primary)
                        Text("Se usa para sugerir sustituciones que sí puedes hacer")
                            .font(.footnote)
                            .foregroundColor(ProgresaColor.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote)
                        .foregroundColor(ProgresaColor.textSecondary)
                }
                .padding(16)
                .background(ProgresaColor.surface)
                .cornerRadius(16)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Cerrar sesión

    private var botonCerrarSesion: some View {
        Button {
            Task { await authViewModel.signOut() }
        } label: {
            HStack {
                Image(systemName: "arrow.right.square")
                Text("Cerrar sesión")
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(ProgresaColor.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(ProgresaColor.accent, lineWidth: 1.5)
        )
    }
}

#Preview {
    PerfilView()
        .environmentObject(AuthViewModel())
}
