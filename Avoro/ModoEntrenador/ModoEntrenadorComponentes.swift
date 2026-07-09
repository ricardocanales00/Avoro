//
//  ModoEntrenadorComponentes.swift
//  Avoro
//
//  Piezas de UI compartidas por las 4 pantallas del flujo de Modo
//  Entrenador (Épica 4, botón placeholder de Home). Todo este flujo es
//  únicamente de navegación — no crea nada en Supabase todavía, salvo la
//  lectura real de `grupo_muscular` en SeleccionMusculosViewModel.
//

import SwiftUI

// MARK: - Header con progreso (4 pasos)

/// Chevron de regreso + título "Modo Entrenador" + barra de progreso
/// segmentada. Se repite igual en las 4 pantallas del flujo.
struct ModoEntrenadorHeader: View {
    let paso: Int
    var totalPasos: Int = 4
    var onBack: () -> Void

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

            HStack(spacing: 6) {
                ForEach(0..<totalPasos, id: \.self) { indice in
                    Capsule()
                        .fill(indice < paso ? ProgresaColor.accent : ProgresaColor.border)
                        .frame(height: 4)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 14)
        .background(ProgresaColor.background)
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
