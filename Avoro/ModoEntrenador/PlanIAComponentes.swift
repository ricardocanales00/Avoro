//
//  PlanIAComponentes.swift
//  Avoro
//
//  Piezas de UI compartidas por las pantallas del wizard "Programa de
//  varios días" (PlanIAWizardView y sus 4 categorías de preguntas).
//  Nuevo, esta sesión.
//

import SwiftUI

// MARK: - Header de 5 categorías (target · calendario · sliders · corazón · sparkles)

/// Stepper de alto nivel: 5 círculos con ícono, conectados por líneas,
/// más una etiqueta de categoría y un contador "x/y" dentro de ella.
/// Distinto del `ModoEntrenadorHeader` de las 2 pantallas iniciales —
/// aquí no hay chevron de regreso ni título, el back vive en el footer
/// (`OnboardingFooterNavegacion`, igual que en el resto del wizard).
struct PlanIACategoriaHeader: View {
    let categoriaActual: PlanIACategoria
    let subPasoActual: Int
    let totalSubPasos: Int

    private let categorias = PlanIACategoria.allCases

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 0) {
                ForEach(Array(categorias.enumerated()), id: \.offset) { index, categoria in
                    circulo(for: categoria)
                    if index < categorias.count - 1 {
                        Rectangle()
                            .fill(colorConector(index))
                            .frame(height: 2)
                    }
                }
            }

            if totalSubPasos > 0 {
                HStack {
                    Text(categoriaActual.etiqueta.uppercased())
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(ProgresaColor.accent)
                        .tracking(0.5)
                    Spacer()
                    Text("\(subPasoActual)/\(totalSubPasos)")
                        .font(.footnote)
                        .foregroundColor(ProgresaColor.textSecondary)
                }
            } else {
                Text(categoriaActual.etiqueta.uppercased())
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(ProgresaColor.accent)
                    .tracking(0.5)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(ProgresaColor.background)
    }

    private enum Estado { case completada, actual, pendiente }

    private func estado(for categoria: PlanIACategoria) -> Estado {
        guard let idxActual = categorias.firstIndex(of: categoriaActual),
              let idx = categorias.firstIndex(of: categoria) else { return .pendiente }
        if idx < idxActual { return .completada }
        if idx == idxActual { return .actual }
        return .pendiente
    }

    @ViewBuilder
    private func circulo(for categoria: PlanIACategoria) -> some View {
        let est = estado(for: categoria)
        ZStack {
            Circle().fill(colorFondo(est))
            switch est {
            case .completada:
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
            case .actual:
                Image(systemName: categoria.icono)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            case .pendiente:
                Image(systemName: categoria.icono)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(ProgresaColor.textSecondary)
            }
        }
        .frame(width: 34, height: 34)
    }

    private func colorFondo(_ estado: Estado) -> Color {
        switch estado {
        case .completada: return ProgresaColor.accent
        case .actual: return ProgresaColor.primary
        case .pendiente: return ProgresaColor.border
        }
    }

    private func colorConector(_ index: Int) -> Color {
        guard let idxActual = categorias.firstIndex(of: categoriaActual) else { return ProgresaColor.border }
        return index < idxActual ? ProgresaColor.accent : ProgresaColor.border
    }
}

// MARK: - Encabezado de pregunta (título + subtítulo + banner "tomado de tu perfil")

struct PlanIAPreguntaHeader: View {
    let titulo: String
    var subtitulo: String? = nil
    var etiquetaTomadoDePerfil: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if etiquetaTomadoDePerfil {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .foregroundColor(ProgresaColor.accent)
                    Text("Tomado de tu perfil · confírmalo o ajústalo")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(ProgresaColor.primary)
                }
                .padding(12)
                .background(ProgresaColor.accent.opacity(0.12))
                .cornerRadius(12)
            }

            Text(titulo)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(ProgresaColor.primary)

            if let subtitulo {
                Text(subtitulo)
                    .font(.subheadline)
                    .foregroundColor(ProgresaColor.textSecondary)
            }
        }
    }
}

// MARK: - Tarjeta de opción única (radio) con emoji opcional

/// Fila de selección única: emoji en círculo blanco (opcional) + título +
/// indicador de radio a la derecha. Distinta de `OnboardingRadioCard`
/// (que usa SF Symbols) porque las capturas de este flujo usan emoji.
struct PlanIAOpcionCard: View {
    let emoji: String?
    let titulo: String
    let seleccionado: Bool
    let accion: () -> Void

    var body: some View {
        Button(action: accion) {
            HStack(spacing: 14) {
                if let emoji {
                    ZStack {
                        Circle().fill(Color.white)
                        Text(emoji).font(.system(size: 18))
                    }
                    .frame(width: 40, height: 40)
                }

                Text(titulo)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ProgresaColor.primary)

                Spacer()

                Circle()
                    .strokeBorder(seleccionado ? ProgresaColor.primary : ProgresaColor.border, lineWidth: seleccionado ? 6 : 1.5)
                    .frame(width: 22, height: 22)
            }
            .padding(16)
            .background(ProgresaColor.surface)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Contenedor de paso (header + contenido scrollable + footer de navegación)

/// Envuelve cada una de las 4 pantallas de categoría (Objetivo,
/// Disponibilidad, Preferencias, Datos físicos): arriba el
/// `PlanIACategoriaHeader`, en medio el contenido de la pregunta actual,
/// abajo `OnboardingFooterNavegacion` (mismo componente que ya usa el
/// onboarding) resolviendo atrás/continuar contra el ViewModel.
struct PlanIAPasoContenedor<Content: View>: View {
    @ObservedObject var viewModel: PlanIAViewModel
    /// Se dispara al tocar "Atrás" en el primer sub-paso de la primera
    /// categoría (objetivo, 1/2) — sale del wizard por completo.
    let onExit: () -> Void
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            PlanIACategoriaHeader(
                categoriaActual: viewModel.categoriaActual,
                subPasoActual: viewModel.subPasoActual,
                totalSubPasos: viewModel.totalSubPasosCategoriaActual
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    content()
                }
                .padding(20)
            }

            OnboardingFooterNavegacion(
                mostrarAtras: true,
                tituloBotonPrincipal: viewModel.esUltimoPasoDePreguntas ? "Generar mi plan" : "Continuar",
                deshabilitado: !viewModel.puedeContinuar,
                cargando: false,
                onAtras: {
                    if viewModel.esPrimerPaso {
                        onExit()
                    } else {
                        viewModel.retroceder()
                    }
                },
                onPrincipal: { viewModel.avanzar() }
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .background(ProgresaColor.background)
        .navigationBarHidden(true)
    }
}
