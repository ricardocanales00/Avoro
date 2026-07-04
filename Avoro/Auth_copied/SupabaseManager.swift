import Foundation
import Supabase

/// Punto único de acceso al cliente de Supabase.
/// Si ya tienes un singleton similar en tu proyecto, usa el tuyo
/// y elimina este archivo para no duplicar la conexión.
final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        // TODO: reemplaza con tu URL y anon key reales de Supabase.
        // El anon key es seguro de embeber en el cliente (está diseñado
        // para eso); lo que NUNCA debe ir en la app es el service_role key.
        guard let url = URL(string: "https://TU-PROYECTO.supabase.co") else {
            fatalError("URL de Supabase inválida")
        }

        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: "TU-ANON-KEY"
        )
    }
}
