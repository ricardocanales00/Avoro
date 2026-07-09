import Foundation
import Combine
import Supabase

// MARK: - Payloads de guardado

private struct OnboardingDatosBasicosUpdate: Encodable {
    let edad: Int
    let estatura_cm: Double
    let peso_actual: Double
    let unidad_preferida: String
    let experiencia: String
    let lugar_entrenamiento: String
}

private struct OnboardingCompletadoUpdate: Encodable {
    let onboarding_completado: Bool
}

@MainActor
final class OnboardingViewModel: ObservableObject {
    /// 0 = edad, 1 = estatura, 2 = peso, 3 = experiencia, 4 = lugar,
    /// 5 = equipo (último paso, reutiliza EditarEquipoViewModel aparte).
    @Published var pasoActual: Int = 0
    let totalPasos = 6

    // MARK: Respuestas

    @Published var edad: Int = 25

    @Published var estaturaCm: Double = 170
    @Published var unidadEstatura: String = "cm" // "cm" | "ft"

    @Published var pesoActual: Double = 70
    @Published var unidadPeso: String = "kg" // "kg" | "lb"

    @Published var experiencia: ExperienciaNivel?
    @Published var lugarEntrenamiento: LugarEntrenamiento?

    // MARK: Estado de guardado

    @Published var isSaving = false
    @Published var errorMessage: String?
    /// Se pone en `true` cuando terminan los 5 pasos básicos y ya se
    /// guardaron — la vista usa esto para navegar al paso de equipo.
    @Published var datosBasicosGuardados = false
    /// Se pone en `true` cuando el wizard completo termina (con o sin
    /// equipo elegido) — quien presente el wizard debe reaccionar a esto
    /// para regresar a la app normal.
    @Published var onboardingCompletado = false

    private let client = SupabaseService.shared.client
    private let kgALb = 2.20462
    private let cmAPulgada = 2.54

    var usuarioId: UUID? { client.auth.currentUser?.id }

    // MARK: - Conversión de estatura (para mostrar en pies/pulgadas)

    var estaturaPiesPulgadas: (pies: Int, pulgadas: Int) {
        let totalPulgadas = Int((estaturaCm / cmAPulgada).rounded())
        return (totalPulgadas / 12, totalPulgadas % 12)
    }

    func incrementarEstatura() {
        estaturaCm += unidadEstatura == "cm" ? 1 : cmAPulgada
    }

    func decrementarEstatura() {
        estaturaCm = max(50, estaturaCm - (unidadEstatura == "cm" ? 1 : cmAPulgada))
    }

    // MARK: - Conversión de peso (al cambiar de unidad, convierte el número
    // ya capturado en vez de reiniciarlo — mismo criterio que el resto de
    // la app al cambiar kg/lb).

    func cambiarUnidadPeso(_ nueva: String) {
        guard nueva != unidadPeso else { return }
        if nueva == "lb" {
            pesoActual = (pesoActual * kgALb).rounded()
        } else {
            pesoActual = (pesoActual / kgALb).rounded()
        }
        unidadPeso = nueva
    }

    func incrementarPeso() {
        pesoActual += 1
    }

    func decrementarPeso() {
        pesoActual = max(1, pesoActual - 1)
    }

    // MARK: - Navegación

    func avanzar() {
        guard pasoActual < totalPasos - 1 else { return }
        pasoActual += 1
    }

    func retroceder() {
        guard pasoActual > 0 else { return }
        pasoActual -= 1
    }

    // MARK: - Guardado

    /// Guarda edad, estatura, peso, unidad preferida, experiencia y lugar
    /// de entrenamiento — todo lo recabado en los primeros 5 pasos. Se
    /// llama justo antes de mostrar el paso de equipo, así que si el
    /// usuario sale de la app a la mitad, ya no pierde lo que llevaba.
    func guardarDatosBasicos() async {
        guard let usuarioId else {
            errorMessage = "No se encontró tu sesión."
            return
        }
        guard let experiencia, let lugarEntrenamiento else {
            errorMessage = "Faltan datos por completar."
            return
        }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        let estaturaEnCm = unidadEstatura == "cm" ? estaturaCm : estaturaCm // ya vive en cm internamente

        do {
            try await client
                .from("perfiles")
                .update(
                    OnboardingDatosBasicosUpdate(
                        edad: edad,
                        estatura_cm: estaturaEnCm,
                        peso_actual: pesoActual,
                        unidad_preferida: unidadPeso,
                        experiencia: experiencia.rawValue,
                        lugar_entrenamiento: lugarEntrenamiento.rawValue
                    )
                )
                .eq("id", value: usuarioId)
                .execute()

            datosBasicosGuardados = true
            avanzar()
        } catch {
            errorMessage = "No se pudo guardar tu información. Intenta de nuevo."
        }
    }

    /// Marca `onboarding_completado = true`. Se llama tanto si el usuario
    /// eligió equipo como si tocó "Agregar después" — en ambos casos ya
    /// terminó el wizard, la diferencia es si `usuario_equipo` quedó con
    /// filas o no.
    func finalizarOnboarding() async {
        guard let usuarioId else { return }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            try await client
                .from("perfiles")
                .update(OnboardingCompletadoUpdate(onboarding_completado: true))
                .eq("id", value: usuarioId)
                .execute()
            onboardingCompletado = true
        } catch {
            errorMessage = "No se pudo finalizar tu configuración. Intenta de nuevo."
        }
    }
}

// MARK: - Enums de UI (coinciden con los enums de Postgres agregados en
// la migración: experiencia_nivel, lugar_entrenamiento_tipo)

enum ExperienciaNivel: String, CaseIterable {
    case nunca
    case menos_1_anio
    case entre_1_y_3_anios
    case mas_3_anios

    var titulo: String {
        switch self {
        case .nunca: return "Nunca he entrenado"
        case .menos_1_anio: return "Menos de 1 año"
        case .entre_1_y_3_anios: return "Entre 1 y 3 años"
        case .mas_3_anios: return "Más de 3 años constante"
        }
    }

    var icono: String {
        switch self {
        case .nunca: return "leaf"
        case .menos_1_anio: return "dumbbell"
        case .entre_1_y_3_anios: return "medal"
        case .mas_3_anios: return "flame"
        }
    }
}

enum LugarEntrenamiento: String, CaseIterable {
    case gimnasio_completo
    case casa
    case gimnasio_basico

    var titulo: String {
        switch self {
        case .gimnasio_completo: return "Un gimnasio completo"
        case .casa: return "Mi casa"
        case .gimnasio_basico: return "Gimnasio básico"
        }
    }

    var icono: String {
        switch self {
        case .gimnasio_completo: return "building.2"
        case .casa: return "house"
        case .gimnasio_basico: return "dumbbell"
        }
    }
}
