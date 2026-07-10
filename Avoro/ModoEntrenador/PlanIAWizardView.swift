//
//  PlanIAWizardView.swift
//  Avoro
//
//  Wizard de 4 categorías / 10 preguntas que recaba los datos para
//  sugerir un "Programa de varios días" (nuevo, esta sesión). Todo se
//  guarda en memoria en `PlanIAViewModel` — ver PlanIAModels.swift para
//  el detalle de qué se persiste (experiencia/lugar de entrenamiento) y
//  qué no (el resto de las respuestas, que solo viven para el futuro
//  prompt a Groq).
//
//  Flujo: EncendiendoMotorView → PlanIAWizardView → (categorías 1-4) →
//  PlanIAGenerandoView → "Ver mi rutina" → ProgramaVariosDiasView.
//

import SwiftUI

struct PlanIAWizardView: View {
    @StateObject private var viewModel = PlanIAViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            switch viewModel.categoriaActual {
            case .objetivo:
                PlanIAObjetivoView(viewModel: viewModel, onExit: { dismiss() })
            case .disponibilidad:
                PlanIADisponibilidadView(viewModel: viewModel, onExit: { dismiss() })
            case .preferencias:
                PlanIAPreferenciasView(viewModel: viewModel, onExit: { dismiss() })
            case .datosFisicos:
                PlanIADatosFisicosView(viewModel: viewModel, onExit: { dismiss() })
            case .generando:
                PlanIAGenerandoView(viewModel: viewModel)
            }
        }
        .task { await viewModel.cargarValoresDePerfil() }
    }
}

// MARK: - Categoría 1 · Objetivo (2 sub-pasos)

struct PlanIAObjetivoView: View {
    @ObservedObject var viewModel: PlanIAViewModel
    let onExit: () -> Void

    var body: some View {
        PlanIAPasoContenedor(viewModel: viewModel, onExit: onExit) {
            switch viewModel.subPasoActual {
            case 1:
                PlanIAPreguntaHeader(
                    titulo: "¿Qué te\ngustaría lograr?",
                    subtitulo: "Selecciona tu objetivo principal."
                )
                VStack(spacing: 12) {
                    ForEach(ObjetivoPrincipal.allCases, id: \.self) { objetivo in
                        PlanIAOpcionCard(
                            emoji: objetivo.emoji,
                            titulo: objetivo.titulo,
                            seleccionado: viewModel.objetivoPrincipal == objetivo
                        ) {
                            viewModel.objetivoPrincipal = objetivo
                        }
                    }
                }
            default:
                PlanIAPreguntaHeader(
                    titulo: "¿Cuánto tiempo\npuedes dedicar\npor sesión?",
                    subtitulo: "Adaptamos la rutina a tu día a día."
                )
                VStack(spacing: 12) {
                    ForEach(TiempoPorSesion.allCases, id: \.self) { tiempo in
                        PlanIAOpcionCard(
                            emoji: nil,
                            titulo: tiempo.titulo,
                            seleccionado: viewModel.tiempoPorSesion == tiempo
                        ) {
                            viewModel.tiempoPorSesion = tiempo
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Categoría 2 · Disponibilidad (2 sub-pasos)

struct PlanIADisponibilidadView: View {
    @ObservedObject var viewModel: PlanIAViewModel
    let onExit: () -> Void

    var body: some View {
        PlanIAPasoContenedor(viewModel: viewModel, onExit: onExit) {
            switch viewModel.subPasoActual {
            case 1:
                PlanIAPreguntaHeader(titulo: "¿Cuántos días\na la semana\npuedes entrenar?")
                VStack(spacing: 12) {
                    ForEach(DiasPorSemana.allCases, id: \.self) { dias in
                        PlanIAOpcionCard(
                            emoji: nil,
                            titulo: dias.titulo,
                            seleccionado: viewModel.diasPorSemana == dias
                        ) {
                            viewModel.diasPorSemana = dias
                        }
                    }
                }
            default:
                // Reusa el mismo enum/valores que el onboarding
                // (ExperienciaNivel) — ver supuestos en PlanIAModels.swift.
                PlanIAPreguntaHeader(
                    titulo: "¿Cómo describirías\ntu experiencia?",
                    etiquetaTomadoDePerfil: true
                )
                VStack(spacing: 12) {
                    ForEach(ExperienciaNivel.allCases, id: \.self) { nivel in
                        OnboardingRadioCard(
                            icono: nivel.icono,
                            titulo: nivel.titulo,
                            seleccionado: viewModel.experiencia == nivel
                        ) {
                            viewModel.experiencia = nivel
                            viewModel.actualizarExperienciaEnPerfil()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Categoría 3 · Preferencias de entrenamiento (3 sub-pasos)

struct PlanIAPreferenciasView: View {
    @ObservedObject var viewModel: PlanIAViewModel
    let onExit: () -> Void

    var body: some View {
        PlanIAPasoContenedor(viewModel: viewModel, onExit: onExit) {
            switch viewModel.subPasoActual {
            case 1:
                PlanIAPreguntaHeader(
                    titulo: "¿Qué grupos\nmusculares quieres\npriorizar?",
                    subtitulo: "Puedes elegir hasta 3."
                )
                PlanIAChipsGrid(
                    items: GrupoMuscularPlan.allCases,
                    titulo: { $0.titulo },
                    seleccionado: { viewModel.gruposPriorizar.contains($0) },
                    deshabilitado: { !viewModel.gruposPriorizar.contains($0) && viewModel.gruposPriorizar.count >= 3 }
                ) { grupo in
                    if viewModel.gruposPriorizar.contains(grupo) {
                        viewModel.gruposPriorizar.remove(grupo)
                    } else if viewModel.gruposPriorizar.count < 3 {
                        viewModel.gruposPriorizar.insert(grupo)
                    }
                }
            case 2:
                PlanIAPreguntaHeader(titulo: "¿Algún grupo que\nprefieras no trabajar\ntanto?")
                PlanIAChipsGrid(
                    items: GrupoMuscularEvitar.allCases,
                    titulo: { $0.titulo },
                    seleccionado: { viewModel.gruposEvitar.contains($0) }
                ) { grupo in
                    if grupo == .ninguno {
                        viewModel.gruposEvitar = [.ninguno]
                    } else {
                        viewModel.gruposEvitar.remove(.ninguno)
                        if viewModel.gruposEvitar.contains(grupo) {
                            viewModel.gruposEvitar.remove(grupo)
                        } else {
                            viewModel.gruposEvitar.insert(grupo)
                        }
                    }
                }
            default:
                // Reusa LugarEntrenamiento (mismo enum del onboarding).
                PlanIAPreguntaHeader(
                    titulo: "¿Qué equipos\nutilizarías?",
                    etiquetaTomadoDePerfil: true
                )
                VStack(spacing: 12) {
                    ForEach(LugarEntrenamiento.allCases, id: \.self) { lugar in
                        OnboardingRadioCard(
                            icono: lugar.icono,
                            titulo: lugar.titulo,
                            seleccionado: viewModel.lugarEntrenamiento == lugar
                        ) {
                            viewModel.lugarEntrenamiento = lugar
                            viewModel.actualizarLugarEnPerfil()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Categoría 4 · Datos físicos (3 sub-pasos)

struct PlanIADatosFisicosView: View {
    @ObservedObject var viewModel: PlanIAViewModel
    let onExit: () -> Void

    var body: some View {
        PlanIAPasoContenedor(viewModel: viewModel, onExit: onExit) {
            switch viewModel.subPasoActual {
            case 1:
                PlanIAPreguntaHeader(titulo: "¿Tienes alguna\nlesión o limitación?")
                PlanIAChipsGrid(
                    items: LesionLimitacion.allCases,
                    titulo: { $0.titulo },
                    seleccionado: { viewModel.lesiones.contains($0) }
                ) { lesion in
                    if lesion == .ninguna {
                        viewModel.lesiones = [.ninguna]
                    } else {
                        viewModel.lesiones.remove(.ninguna)
                        if viewModel.lesiones.contains(lesion) {
                            viewModel.lesiones.remove(lesion)
                        } else {
                            viewModel.lesiones.insert(lesion)
                        }
                    }
                }
            case 2:
                PlanIAPreguntaHeader(titulo: "¿Qué tan intenso\nte gusta entrenar?")
                VStack(spacing: 12) {
                    ForEach(IntensidadDeseada.allCases, id: \.self) { intensidad in
                        PlanIAOpcionCard(
                            emoji: intensidad.emoji,
                            titulo: intensidad.titulo,
                            seleccionado: viewModel.intensidad == intensidad
                        ) {
                            viewModel.intensidad = intensidad
                        }
                    }
                }
            default:
                PlanIAPreguntaHeader(titulo: "¿Quieres incluir\ncardio?")
                VStack(spacing: 12) {
                    ForEach(PreferenciaCardio.allCases, id: \.self) { cardio in
                        PlanIAOpcionCard(
                            emoji: nil,
                            titulo: cardio.titulo,
                            seleccionado: viewModel.cardio == cardio
                        ) {
                            viewModel.cardio = cardio
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        PlanIAWizardView()
    }
}
