import Foundation
import Combine
import Supabase

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var nombreUsuario = ""
    @Published var nombreBloqueRutina = ""
    @Published var diaDeHoy: DiaConEjercicios?
    @Published var totalRutinasGuardadas = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var sinRutinaActiva = false

    private let rutinaService = RutinaService()
    private let client = SupabaseService.shared.client

    var fechaHoyFormateada: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_MX")
        formatter.dateFormat = "EEEE, d 'de' MMMM"
        return formatter.string(from: Date()).capitalized(with: Locale(identifier: "es_MX"))
    }

    func cargarDatos() async {
        isLoading = true
        errorMessage = nil
        sinRutinaActiva = false
        defer { isLoading = false }

        guard let usuarioId = client.auth.currentUser?.id else {
            errorMessage = "No se encontró tu sesión. Intenta iniciar sesión de nuevo."
            return
        }

        do {
            async let perfilTask = fetchNombrePerfil(usuarioId)
            async let rutinaTask = rutinaService.fetchRutinaActiva(usuarioId: usuarioId)
            async let totalTask = rutinaService.contarRutinas(usuarioId: usuarioId)

            nombreUsuario = try await perfilTask
            totalRutinasGuardadas = try await totalTask

            if let rutina = try await rutinaTask {
                nombreBloqueRutina = rutina.nombre
                diaDeHoy = diaCorrespondienteAHoy(rutina: rutina)
            } else {
                sinRutinaActiva = true
            }
        } catch {
            errorMessage = "No se pudo cargar tu rutina de hoy. Desliza hacia abajo para reintentar."
        }
    }

    /// NOTA IMPORTANTE: el schema actual no guarda a qué día de la semana
    /// corresponde cada `dia_rutina` — solo un `orden` (1, 2, 3...).
    /// Aquí ciclamos los días según cuántos días naturales han pasado
    /// desde `fecha_inicio`, para que "el día de hoy" avance solo.
    ///
    /// Si en vez de esto quieres días fijos (ej. "el Día 1 siempre es
    /// lunes, descansa fin de semana"), la solución es agregar una
    /// columna `dia_semana` (o un array de días) a `dia_rutina` y
    /// cambiar esta función para que busque por weekday en vez de ciclar.
    private func diaCorrespondienteAHoy(rutina: RutinaConDias) -> DiaConEjercicios? {
        guard !rutina.dias.isEmpty else { return nil }
        let diasOrdenados = rutina.dias.sorted { $0.orden < $1.orden }

        let diasTranscurridos = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: rutina.fechaInicioComoDate),
            to: Calendar.current.startOfDay(for: Date())
        ).day ?? 0

        let indice = ((diasTranscurridos % diasOrdenados.count) + diasOrdenados.count) % diasOrdenados.count
        return diasOrdenados[indice]
    }

    private func fetchNombrePerfil(_ usuarioId: UUID) async throws -> String {
        let perfil: Perfil = try await client
            .from("perfiles")
            .select()
            .eq("id", value: usuarioId)
            .single()
            .execute()
            .value
        return perfil.nombre
    }
}
