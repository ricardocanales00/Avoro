//
//  ModoEntrenadorInicioView.swift
//  Avoro
//
//  Paso 1 del flujo. Se abre desde el botón "Modo Entrenador" de la card
//  del día en HomeView. "Seguir mi rutina establecida" reutiliza el flujo
//  real ya existente (EjecucionRutinaView); "Sugiéreme una rutina" entra
//  al flujo nuevo (TipoRutinaView → ... → PlanIAWizardView).
//
//  ACTUALIZADO ESTA SESIÓN: la barra de progreso del header ya no es el
//  stepper segmentado de "4 pasos" — ahora usa `ModoEntrenadorHeader(
//  progreso:)`, una barra continua de dos tramos, porque el número total
//  de pasos depende de qué elige el usuario en esta y la siguiente
//  pantalla (ver ModoEntrenadorComponentes.swift). Esta pantalla es la
//  1ª de 2 antes de bifurcar, por eso usa un progreso menor (0.4) que
//  `TipoRutinaView` (0.8).
//

import SwiftUI

struct ModoEntrenadorInicioView: View {
    @Environment(\.dismiss) private var dismiss

    /// Datos reales del día que ya se mostraba en Home cuando el usuario
    /// tocó "Modo Entrenador" — se usan para el subtítulo de "Seguir mi
    /// rutina establecida" y para poder llevarlo directo a
    /// EjecucionRutinaView si elige esa opción (mismo flujo que "Iniciar
    /// rutina", ya funcional).
    let diaActual: DiaConEjercicios?
    let unidadPreferida: String
    let fechaSeleccionada: Date

    @State private var irASeguirRutina = false
    @State private var irATipoRutina = false

    var body: some View {
        VStack(spacing: 0) {
            ModoEntrenadorHeader(progreso: 0.4, onBack: { dismiss() })

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("¿Cómo quieres entrenar hoy?")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(ProgresaColor.primary)
                    Text("Tu entrenador puede guiarte con tu rutina o proponerte una nueva.")
                        .font(.subheadline)
                        .foregroundColor(ProgresaColor.textSecondary)
                }
                .padding(.top, 8)

                OpcionCard(
                    icono: "list.clipboard",
                    colorIcono: ProgresaColor.primary,
                    colorFondoIcono: ProgresaColor.background,
                    titulo: "Seguir mi rutina establecida",
                    subtitulo: subtituloRutinaActual
                ) {
                    irASeguirRutina = true
                }

                OpcionCard(
                    icono: "wand.and.stars",
                    colorIcono: .white,
                    colorFondoIcono: ProgresaColor.primary,
                    titulo: "Sugiéreme una rutina",
                    subtitulo: "Crea una rutina a tu medida según los músculos que quieras trabajar.",
                    destacada: true
                ) {
                    irATipoRutina = true
                }

                Spacer()
            }
            .padding(20)
        }
        .background(ProgresaColor.background)
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $irASeguirRutina) {
            if let dia = diaActual {
                EjecucionRutinaView(dia: dia, unidadPreferida: unidadPreferida, fecha: fechaSeleccionada)
            }
        }
        .navigationDestination(isPresented: $irATipoRutina) {
            TipoRutinaView()
        }
    }

    private var subtituloRutinaActual: String {
        guard let dia = diaActual else {
            return "No tienes una rutina asignada para hoy."
        }
        return "Hoy toca \(dia.nombreDia)."
    }
}

#Preview {
    NavigationStack {
        ModoEntrenadorInicioView(diaActual: nil, unidadPreferida: "kg", fechaSeleccionada: Date())
    }
}
