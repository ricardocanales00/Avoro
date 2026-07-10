//
//  ModoEntrenadorComponentes.swift
//  Avoro
//
//  Piezas de UI compartidas por las pantallas del flujo de Modo
//  Entrenador (Épica 4). Todo este flujo es únicamente de navegación por
//  ahora — no crea nada en Supabase todavía, salvo la lectura real de
//  `grupo_muscular` en SeleccionMusculosViewModel y, desde esta sesión,
//  la actualización de `nivel_experiencia` / `lugar_entrenamiento` del
//  perfil cuando el usuario los ajusta dentro del wizard de sugerencia
//  de rutina (ver PlanIAModels.swift).
//
//  ACTUALIZADO ESTA SESIÓN: `ModoEntrenadorHeader` ahora soporta dos
//  estilos de barra de progreso:
//   - `.segmentada`: el original, N capsulas discretas (se sigue usando
//     en `ProgramaVariosDiasView`, paso 4 de 4).
//   - `.proporcional`: una sola barra continua (naranja/gris) sin marcar
//     cuántos pasos hay en total. Se usa en `ModoEntrenadorInicioView` y
//     `TipoRutinaView`, porque el número total de pasos del flujo
//     depende de qué elige el usuario (seguir rutina vs. sugerencia; un
//     solo día vs. programa de varios días) y un stepper de "4 pasos"
//     fijo ya no describe la realidad del flujo.
//
//  También se agregó `PlanIAChip` / `PlanIAChipsGrid`, para la selección
//  múltiple del wizard de sugerencia de rutina (Sección 7.17). Reutilizan
//  `FlowLayout` (definido en `EquipoComponentes.swift`) para el wrap y
//  copian el estilo visual de `EquipoPill`, así que este archivo asume
//  que `EquipoComponentes.swift` está en el mismo target.
//

import SwiftUI

// MARK: - Header con progreso

/// Chevron de regreso + título "Modo Entrenador" + barra de progreso.
/// Se repite en las pantallas iniciales del flujo (Inicio, TipoRutina) y,
/// en su modo segmentado, en `ProgramaVariosDiasView`.
struct ModoEntrenadorHeader: View {
    enum Barra {
        case segmentada(actual: Int, total: Int)
        case proporcional(progreso: CGFloat)
    }

    private let barra: Barra
    var onBack: () -> Void

    /// Compatibilidad con las pantallas que ya usaban el stepper de N
    /// pasos fijos (ej. `ProgramaVariosDiasView(paso: 4)`).
    init(paso: Int, totalPasos: Int = 4, onBack: @escaping () -> Void) {
        self.barra = .segmentada(actual: paso, total: totalPasos)
        self.onBack = onBack
    }

    /// Nuevo: barra continua proporcional, sin número de pasos fijo.
    init(progreso: CGFloat, onBack: @escaping () -> Void) {
        self.barra = .proporcional(progreso: progreso)
        self.onBack = onBack
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(ProgresaColor.primary)
                }

                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .foregroundColor(ProgresaColor.accent)
                    Text("Modo Entrenador")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(ProgresaColor.primary)
                }

                Spacer()
            }

            switch barra {
            case let .segmentada(actual, total):
                HStack(spacing: 6) {
                    ForEach(0..<total, id: \.self) { indice in
                        Capsule()
                            .fill(indice < actual ? ProgresaColor.accent : ProgresaColor.border)
                            .frame(height: 4)
                    }
                }
            case let .proporcional(progreso):
                ModoEntrenadorProgresoSimple(progreso: progreso)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 14)
        .background(ProgresaColor.background)
    }
}

/// Barra de progreso de dos tramos (avance / restante), sin segmentos
/// discretos — pensada para flujos donde el número total de pasos no se
/// conoce de antemano (depende de la rama que elija el usuario).
struct ModoEntrenadorProgresoSimple: View {
    /// 0...1. Cuánto se considera avanzado dentro de estas pantallas.
    let progreso: CGFloat

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 6) {
                Capsule()
                    .fill(ProgresaColor.accent)
                    .frame(width: max(28, geo.size.width * min(max(progreso, 0), 1)), height: 4)
                Capsule()
                    .fill(ProgresaColor.border)
                    .frame(height: 4)
            }
        }
        .frame(height: 4)
    }
}

// MARK: - Tarjeta de opción (Seguir rutina / Sugiéreme / Un solo día / Programa)

/// `destacada` resalta las opciones "asistidas por IA" con ícono en fondo
/// navy y borde más grueso, igual que en las capturas de referencia.
struct OpcionCard: View {
    let icono: String
    let colorIcono: Color
    let colorFondoIcono: Color
    let titulo: String
    let subtitulo: String
    var destacada = false
    let accion: () -> Void

    var body: some View {
        Button(action: accion) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorFondoIcono)
                    Image(systemName: icono)
                        .foregroundColor(colorIcono)
                        .font(.system(size: 18, weight: .semibold))
                }
                .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 2) {
                    Text(titulo)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(ProgresaColor.primary)
                    Text(subtitulo)
                        .font(.footnote)
                        .foregroundColor(ProgresaColor.textSecondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .foregroundColor(ProgresaColor.textSecondary)
            }
            .padding(16)
            .background(ProgresaColor.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(destacada ? ProgresaColor.primary : ProgresaColor.border, lineWidth: destacada ? 2 : 1)
            )
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Chip de selección múltiple (grupos musculares, lesiones, etc.)

/// Usado en los pasos del wizard de sugerencia de rutina que piden
/// selección múltiple sobre una lista corta (grupos musculares a
/// priorizar/evitar, lesiones).
///
/// ACTUALIZADO ESTA SESIÓN: antes usaba un `LazyVGrid` adaptativo propio
/// y un estilo de rectángulo redondeado inventado. Ahora reutiliza
/// `FlowLayout` (definido en `EquipoComponentes.swift`, ya usado por
/// `EquipoSeleccionGrid`) para el wrap, y copia el estilo visual de
/// `EquipoPill` (cápsula + checkmark) para que las selecciones múltiples
/// se vean igual en toda la app. No se reutiliza `EquipoPill` tal cual
/// porque está tipado a `Equipo`, no a un `Item: Hashable` genérico —
/// si en algún momento se quiere un solo componente, valdría la pena
/// genericizar `EquipoPill` y hacer que ambos usen la misma base.
struct PlanIAChip: View {
    let titulo: String
    let seleccionado: Bool
    var deshabilitado: Bool = false
    let accion: () -> Void

    var body: some View {
        Button(action: accion) {
            HStack(spacing: 6) {
                if seleccionado {
                    Image(systemName: "checkmark")
                }
                Text(titulo)
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(seleccionado ? .white : ProgresaColor.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(seleccionado ? ProgresaColor.primary : Color.clear)
            .overlay(
                Capsule().stroke(seleccionado ? Color.clear : ProgresaColor.border, lineWidth: 1)
            )
            .clipShape(Capsule())
            .opacity(deshabilitado && !seleccionado ? 0.4 : 1)
        }
        .disabled(deshabilitado && !seleccionado)
    }
}

/// Wrap de `PlanIAChip` usando `FlowLayout` — mismo mecanismo de
/// wrap que `EquipoSeleccionGrid`, sin el agrupado por categoría (aquí
/// las listas ya son planas: grupos musculares, lesiones, etc.).
struct PlanIAChipsGrid<Item: Hashable>: View {
    let items: [Item]
    let titulo: (Item) -> String
    let seleccionado: (Item) -> Bool
    var deshabilitado: (Item) -> Bool = { _ in false }
    let toggle: (Item) -> Void

    var body: some View {
        FlowLayout(spacing: 10) {
            ForEach(items, id: \.self) { item in
                PlanIAChip(
                    titulo: titulo(item),
                    seleccionado: seleccionado(item),
                    deshabilitado: deshabilitado(item)
                ) {
                    toggle(item)
                }
            }
        }
    }
}

// MARK: - Ejercicio de ejemplo (contenido mock, no persistido)

/// En la versión real, este contenido vendría de una respuesta tipo LLM
/// (igual que el catálogo real que ya usa `sustituir-ejercicio`). Por
/// ahora es un modelo local en memoria, solo para poder mostrar y
/// reordenar/eliminar en pantalla sin tocar Supabase.
struct EjercicioMock: Identifiable {
    let id = UUID()
    var nombre: String
    var series: Int
    var reps: Int
    var musculo: String
}

/// Fila reutilizada tanto en `RutinaUnDiaPropuestaView` (imagen 7) como en
/// `ProgramaVariosDiasView` (imagen 5): imagen placeholder, nombre,
/// series×reps + músculo, flechas de reordenar, sustituir y eliminar.
struct EjercicioMockRow: View {
    let ejercicio: EjercicioMock
    let puedeSubir: Bool
    let puedeBajar: Bool
    let onSubir: () -> Void
    let onBajar: () -> Void
    let onSustituir: () -> Void
    let onEliminar: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            VStack(spacing: 6) {
                Button(action: onSubir) {
                    Image(systemName: "arrow.up")
                }
                .disabled(!puedeSubir)
                .opacity(puedeSubir ? 1 : 0.3)

                Button(action: onBajar) {
                    Image(systemName: "arrow.down")
                }
                .disabled(!puedeBajar)
                .opacity(puedeBajar ? 1 : 0.3)
            }
            .font(.footnote)
            .foregroundColor(ProgresaColor.textSecondary)

            ZStack {
                Color(ProgresaColor.border)
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundColor(ProgresaColor.textSecondary)
            }
            .frame(width: 44, height: 44)
            .cornerRadius(10)
            .clipped()

            VStack(alignment: .leading, spacing: 2) {
                Text(ejercicio.nombre)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(ProgresaColor.primary)
                    .lineLimit(1)
                Text("\(ejercicio.series) x \(ejercicio.reps) · \(ejercicio.musculo)")
                    .font(.footnote)
                    .foregroundColor(ProgresaColor.textSecondary)
            }

            Spacer()

            Button(action: onSustituir) {
                Image(systemName: "arrow.triangle.2.circlepath")
            }
            Button(action: onEliminar) {
                Image(systemName: "xmark")
            }
        }
        .foregroundColor(ProgresaColor.textSecondary)
        .padding(10)
        .background(ProgresaColor.surface)
        .cornerRadius(12)
    }
}
