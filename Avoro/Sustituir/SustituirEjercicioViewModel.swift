import Foundation
import Combine

@MainActor
final class SustituirEjercicioViewModel: ObservableObject {
    let ejercicioDiaId: UUID
    let ejercicioOriginal: EjercicioResumen
    let usuarioId: UUID

    @Published var mensajes: [MensajeChatSustitucion] = []
    @Published var textoInput = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    /// Cuando no es `nil`, la vista debe cerrar el chat y devolver este
    /// ejercicio como el nuevo sustituto (ya aplicado en la BD).
    @Published var ejercicioSustituto: EjercicioResumen?

    private let service = SustitucionService()

    init(ejercicioDiaId: UUID, ejercicioOriginal: EjercicioResumen, usuarioId: UUID) {
        self.ejercicioDiaId = ejercicioDiaId
        self.ejercicioOriginal = ejercicioOriginal
        self.usuarioId = usuarioId
    }

    /// Dispara la primera recomendación en cuanto se abre el chat, antes de
    /// que el usuario escriba nada.
    func iniciarConversacion() async {
        guard mensajes.isEmpty else { return }
        await pedirAlAsistente()
    }

    func enviarMensaje() async {
        let texto = textoInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !texto.isEmpty else { return }

        mensajes.append(MensajeChatSustitucion(rol: .usuario, texto: texto))
        textoInput = ""
        await pedirAlAsistente()
    }

    private func pedirAlAsistente() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let historial = mensajes.map {
                HistorialItemPayload(role: $0.rol == .usuario ? "user" : "model", texto: $0.texto)
            }

            let respuesta = try await service.pedirSugerencias(
                usuarioId: usuarioId,
                ejercicioActualId: ejercicioOriginal.id,
                grupoMuscular: ejercicioOriginal.grupoMuscular,
                historial: historial
            )

            mensajes.append(
                MensajeChatSustitucion(rol: .asistente, texto: respuesta.mensaje, sugerencias: respuesta.sugerencias)
            )
        } catch {
            print("❌ Error al pedir sugerencia:", error)
            errorMessage = "No se pudo contactar al asistente. Intenta de nuevo."
        }
    }

    /// El usuario tocó "Usar este ejercicio" en una tarjeta de sugerencia.
    func confirmarSustitucion(_ sugerencia: SugerenciaEjercicio) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await service.sustituirEjercicio(
                ejercicioDiaId: ejercicioDiaId,
                ejercicioOriginalId: ejercicioOriginal.id,
                ejercicioSustitutoId: sugerencia.ejercicio.id
            )
            ejercicioSustituto = sugerencia.ejercicio
        } catch {
            errorMessage = "No se pudo aplicar la sustitución. Intenta de nuevo."
        }
    }
}
