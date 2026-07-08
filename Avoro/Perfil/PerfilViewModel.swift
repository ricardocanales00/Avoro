import Foundation
import Combine
import Supabase

@MainActor
final class PerfilViewModel: ObservableObject {
    @Published var nombre = ""
    @Published var email = ""
    @Published var unidadPreferida = "kg"
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let client = SupabaseService.shared.client

    var iniciales: String {
        let partes = nombre.split(separator: " ")
        let letras = partes.prefix(2).compactMap { $0.first }
        return letras.isEmpty ? "?" : String(letras).uppercased()
    }

    func cargar() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        guard let usuario = client.auth.currentUser else {
            errorMessage = "No se encontró tu sesión."
            return
        }
        email = usuario.email ?? ""

        do {
            let perfil: Perfil = try await client
                .from("perfiles")
                .select()
                .eq("id", value: usuario.id)
                .single()
                .execute()
                .value
            nombre = perfil.nombre
            unidadPreferida = perfil.unidadPreferida
        } catch {
            errorMessage = "No se pudo cargar tu perfil."
        }
    }

    /// Actualización optimista: cambia el toggle de inmediato y revierte
    /// si el guardado en Supabase falla.
    func actualizarUnidad(_ unidad: String) async {
        guard unidad != unidadPreferida else { return }
        let anterior = unidadPreferida
        unidadPreferida = unidad

        guard let usuarioId = client.auth.currentUser?.id else { return }

        do {
            try await client
                .from("perfiles")
                .update(["unidad_preferida": unidad])
                .eq("id", value: usuarioId)
                .execute()
        } catch {
            unidadPreferida = anterior
            errorMessage = "No se pudo actualizar tu unidad preferida."
        }
    }
}
