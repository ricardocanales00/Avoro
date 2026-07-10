//
//  PlanIAModels.swift
//  Avoro
//
//  Modelos y ViewModel del wizard "Programa de varios días" dentro de
//  Modo Entrenador (nuevo, esta sesión). Todo lo que este wizard recaba
//  se guarda solo en memoria (`@Published` en `PlanIAViewModel`) — nada
//  se persiste en Supabase todavía, salvo dos excepciones puntuales:
//  `experiencia` y `lugarEntrenamiento` se prellenan desde `perfiles` y,
//  si el usuario los cambia aquí, también se actualizan ahí (mismo
//  criterio que Editar Perfil, Épica 8), porque son datos reales del
//  perfil, no solo del prompt de esta rutina.
//
//  ACTUALIZADO ESTA SESIÓN: la lectura/escritura de `nivel_experiencia` y
//  `lugar_entrenamiento` ya no vive aquí como queries sueltas — se movió a
//  `EquipoService` (`fetchDatosPerfilParaPlanIA`, `actualizarNivelExperiencia`,
//  `actualizarLugarEntrenamiento`), que es donde ya vivía el resto de la
//  lógica de perfil/equipo (`actualizarUnidadPreferida`). El ViewModel solo
//  resuelve el `usuarioId` y llama al service, igual que el resto del
//  proyecto (ViewModel delgado + Service con las queries).
//
//  IMPORTANTE / SUPUESTOS A VALIDAR:
//  - Se asume que `ExperienciaNivel` y `LugarEntrenamiento` (declarados
//    junto a `OnboardingViewModel`, no incluidos en los archivos que
//    compartiste esta sesión) exponen `allCases`, `.icono` (SF Symbol) y
//    `.titulo`, y que sus `rawValue` de tipo `String` coinciden con lo
//    guardado en `perfiles`. Si sus rawValues no son un `String` plano,
//    ajusta los métodos correspondientes en `EquipoService`.
//  - Se asume que las columnas de `perfiles` se llaman `nivel_experiencia`
//    y `lugar_entrenamiento` (mencionadas en la Sección 8 del documento de
//    requisitos, pero sin nombre de columna confirmado). Ajusta los
//    structs `Encodable`/`Decodable` en `EquipoService` si difieren.
//  - Ninguna de estas respuestas se manda a Groq todavía: eso queda
//    pendiente para cuando se conecte `PlanIAGenerandoView` a la Edge
//    Function real (ver TODO ahí).
//

import Foundation
import Combine // requerido por `ObservableObject` / `@Published` en PlanIAViewModel
import Supabase

// MARK: - Categorías del wizard (usadas por el header de 5 pasos)

enum PlanIACategoria: CaseIterable {
    case objetivo
    case disponibilidad
    case preferencias
    case datosFisicos
    case generando

    var icono: String {
        switch self {
        case .objetivo: return "scope"
        case .disponibilidad: return "calendar"
        case .preferencias: return "slider.horizontal.3"
        case .datosFisicos: return "heart.text.square"
        case .generando: return "sparkles"
        }
    }

    var etiqueta: String {
        switch self {
        case .objetivo: return "Objetivo definido"
        case .disponibilidad: return "Disponibilidad registrada"
        case .preferencias: return "Preferencias de entrenamiento"
        case .datosFisicos: return "Datos físicos"
        case .generando: return "Generando tu plan"
        }
    }
}

// MARK: - Preguntas del wizard

enum ObjetivoPrincipal: String, CaseIterable, Codable {
    case ganarMasaMuscular, perderGrasa, recomposicion, aumentarFuerza, mejorarCondicion

    var titulo: String {
        switch self {
        case .ganarMasaMuscular: return "Ganar masa muscular"
        case .perderGrasa: return "Perder grasa"
        case .recomposicion: return "Recomponer mi cuerpo"
        case .aumentarFuerza: return "Aumentar mi fuerza"
        case .mejorarCondicion: return "Mejorar mi condición física"
        }
    }

    var emoji: String {
        switch self {
        case .ganarMasaMuscular: return "💪"
        case .perderGrasa: return "🔥"
        case .recomposicion: return "⚖️"
        case .aumentarFuerza: return "🏋️"
        case .mejorarCondicion: return "❤️"
        }
    }
}

enum TiempoPorSesion: String, CaseIterable, Codable {
    case min30, min45, min60, min75, min90Mas

    var titulo: String {
        switch self {
        case .min30: return "30 minutos"
        case .min45: return "45 minutos"
        case .min60: return "60 minutos"
        case .min75: return "75 minutos"
        case .min90Mas: return "90 minutos o más"
        }
    }
}

enum DiasPorSemana: Int, CaseIterable, Codable {
    case dos = 2, tres = 3, cuatro = 4, cinco = 5, seis = 6, siete = 7

    var titulo: String { "\(rawValue) días" }
}

enum GrupoMuscularPlan: String, CaseIterable, Codable {
    case pecho, espalda, hombros, biceps, triceps, abdomen, gluteos, cuadriceps, femorales, pantorrillas

    var titulo: String {
        switch self {
        case .pecho: return "Pecho"
        case .espalda: return "Espalda"
        case .hombros: return "Hombros"
        case .biceps: return "Bíceps"
        case .triceps: return "Tríceps"
        case .abdomen: return "Abdomen"
        case .gluteos: return "Glúteos"
        case .cuadriceps: return "Cuádriceps"
        case .femorales: return "Femorales"
        case .pantorrillas: return "Pantorrillas"
        }
    }
}

enum GrupoMuscularEvitar: String, CaseIterable, Codable {
    case ninguno, pecho, espalda, hombros, brazos, piernas, abdomen

    var titulo: String {
        switch self {
        case .ninguno: return "Ninguno"
        case .pecho: return "Pecho"
        case .espalda: return "Espalda"
        case .hombros: return "Hombros"
        case .brazos: return "Brazos"
        case .piernas: return "Piernas"
        case .abdomen: return "Abdomen"
        }
    }
}

enum LesionLimitacion: String, CaseIterable, Codable {
    case ninguna, rodilla, espaldaBaja, hombro, codo, tobillo, otra

    var titulo: String {
        switch self {
        case .ninguna: return "Ninguna"
        case .rodilla: return "Rodilla"
        case .espaldaBaja: return "Espalda baja"
        case .hombro: return "Hombro"
        case .codo: return "Codo"
        case .tobillo: return "Tobillo"
        case .otra: return "Otra"
        }
    }
}

enum IntensidadDeseada: String, CaseIterable, Codable {
    case tranquilo, moderado, intenso, muyIntenso

    var titulo: String {
        switch self {
        case .tranquilo: return "Tranquilo"
        case .moderado: return "Moderado"
        case .intenso: return "Intenso"
        case .muyIntenso: return "Muy intenso"
        }
    }

    var emoji: String {
        switch self {
        case .tranquilo: return "😊"
        case .moderado: return "🙂"
        case .intenso: return "😤"
        case .muyIntenso: return "🔥"
        }
    }
}

enum PreferenciaCardio: String, CaseIterable, Codable {
    case no, unaDosVeces, tresCuatroVeces, despuesDeCadaEntrenamiento

    var titulo: String {
        switch self {
        case .no: return "No"
        case .unaDosVeces: return "Sí, 1–2 veces por semana"
        case .tresCuatroVeces: return "Sí, 3–4 veces por semana"
        case .despuesDeCadaEntrenamiento: return "Sí, después de cada entrenamiento"
        }
    }
}

// MARK: - ViewModel

@MainActor
final class PlanIAViewModel: ObservableObject {
    // Paso 1 · Objetivo
    @Published var objetivoPrincipal: ObjetivoPrincipal?
    @Published var tiempoPorSesion: TiempoPorSesion?

    // Paso 2 · Disponibilidad
    @Published var diasPorSemana: DiasPorSemana?
    /// Prellenado desde `perfiles.nivel_experiencia`. Editable aquí.
    @Published var experiencia: ExperienciaNivel?

    // Paso 3 · Preferencias de entrenamiento
    @Published var gruposPriorizar: Set<GrupoMuscularPlan> = []
    @Published var gruposEvitar: Set<GrupoMuscularEvitar> = []
    /// Prellenado desde `perfiles.lugar_entrenamiento`. Editable aquí.
    @Published var lugarEntrenamiento: LugarEntrenamiento?

    // Paso 4 · Datos físicos
    @Published var lesiones: Set<LesionLimitacion> = []
    @Published var intensidad: IntensidadDeseada?
    @Published var cardio: PreferenciaCardio?

    // Navegación
    @Published var categoriaActual: PlanIACategoria = .objetivo
    @Published var subPasoActual: Int = 1 // 1-based, dentro de `categoriaActual`

    @Published var errorMessage: String?

    private let client = SupabaseService.shared.client
    /// Reutiliza el service ya existente para leer/escribir `perfiles`
    /// (ver `EquipoService.fetchDatosPerfilParaPlanIA` y los métodos
    /// `actualizar*` agregados ahí en esta misma sesión) en vez de armar
    /// queries sueltas aquí — mismo patrón que el resto del proyecto
    /// (ViewModel delgado + Service con las queries).
    private let equipoService = EquipoService()

    private let totalSubPasosPorCategoria: [PlanIACategoria: Int] = [
        .objetivo: 2,
        .disponibilidad: 2,
        .preferencias: 3,
        .datosFisicos: 3,
        .generando: 0,
    ]

    var totalSubPasosCategoriaActual: Int { totalSubPasosPorCategoria[categoriaActual] ?? 0 }

    var esPrimerPaso: Bool {
        categoriaActual == .objetivo && subPasoActual == 1
    }

    /// El botón principal dice "Generar mi plan" en vez de "Continuar"
    /// justo en el último sub-paso de la última categoría "de preguntas"
    /// (datos físicos), ya que el siguiente avance entra a `.generando`.
    var esUltimoPasoDePreguntas: Bool {
        categoriaActual == .datosFisicos && subPasoActual == totalSubPasosCategoriaActual
    }

    var puedeContinuar: Bool {
        switch (categoriaActual, subPasoActual) {
        case (.objetivo, 1): return objetivoPrincipal != nil
        case (.objetivo, 2): return tiempoPorSesion != nil
        case (.disponibilidad, 1): return diasPorSemana != nil
        case (.disponibilidad, 2): return experiencia != nil
        case (.preferencias, 1): return !gruposPriorizar.isEmpty
        case (.preferencias, 2): return true // opcional: puede no marcar nada
        case (.preferencias, 3): return lugarEntrenamiento != nil
        case (.datosFisicos, 1): return true // opcional: "Ninguna" cuenta como respuesta implícita
        case (.datosFisicos, 2): return intensidad != nil
        case (.datosFisicos, 3): return cardio != nil
        default: return true
        }
    }

    // MARK: Navegación

    func avanzar() {
        let categorias = PlanIACategoria.allCases
        guard let idx = categorias.firstIndex(of: categoriaActual) else { return }

        if subPasoActual < totalSubPasosCategoriaActual {
            subPasoActual += 1
        } else if idx + 1 < categorias.count {
            categoriaActual = categorias[idx + 1]
            subPasoActual = 1
        }
    }

    func retroceder() {
        let categorias = PlanIACategoria.allCases
        guard let idx = categorias.firstIndex(of: categoriaActual) else { return }

        if subPasoActual > 1 {
            subPasoActual -= 1
        } else if idx > 0 {
            categoriaActual = categorias[idx - 1]
            subPasoActual = totalSubPasosPorCategoria[categoriaActual] ?? 1
        }
    }

    // MARK: Perfil (prellenar + sincronizar cambios)

    /// Se llama al entrar al wizard. Trae `nivel_experiencia` y
    /// `lugar_entrenamiento` ya capturados en el onboarding, para no
    /// volver a preguntarlos desde cero (Sección 2.2 y 3.3 del wizard).
    func cargarValoresDePerfil() async {
        guard let userId = client.auth.currentUser?.id else { return }
        do {
            let datos = try await equipoService.fetchDatosPerfilParaPlanIA(usuarioId: userId)
            if let raw = datos.experiencia {
                experiencia = ExperienciaNivel(rawValue: raw)
            }
            if let raw = datos.lugar {
                lugarEntrenamiento = LugarEntrenamiento(rawValue: raw)
            }
        } catch {
            // No bloqueamos el wizard si falla: el usuario simplemente
            // elige los valores manualmente en esos dos pasos.
            errorMessage = "No se pudo cargar tu perfil. Puedes seleccionar los valores manualmente."
        }
    }

    /// Si el usuario cambia su experiencia aquí, además de usarse para el
    /// futuro prompt a Groq, se refleja en su perfil real — mismo dato
    /// que edita desde Perfil (Épica 8).
    func actualizarExperienciaEnPerfil() {
        guard let experiencia, let userId = client.auth.currentUser?.id else { return }
        Task {
            try? await equipoService.actualizarNivelExperiencia(usuarioId: userId, nivelExperiencia: experiencia.rawValue)
        }
    }

    func actualizarLugarEnPerfil() {
        guard let lugarEntrenamiento, let userId = client.auth.currentUser?.id else { return }
        Task {
            try? await equipoService.actualizarLugarEntrenamiento(usuarioId: userId, lugar: lugarEntrenamiento.rawValue)
        }
    }
}
