import Foundation
import Supabase

final class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "https://bxuwgvvjblghrbeossds.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ4dXdndnZqYmxnaHJiZW9zc2RzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMxMzczMTUsImV4cCI6MjA5ODcxMzMxNX0.0jpo-AuecG8GGdDFMvdY0NvNr-Ub2DVCJZLFdJ_p8EM"
        )
    }
}
