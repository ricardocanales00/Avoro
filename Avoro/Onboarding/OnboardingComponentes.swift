import SwiftUI

// MARK: - Barra de progreso por segmentos (uno por paso del wizard)

struct OnboardingProgressBar: View {
    let pasoActual: Int
    let totalPasos: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalPasos, id: \.self) { indice in
                Capsule()
                    .fill(indice <= pasoActual ? Color.orange : ProgresaColor.border)
                    .frame(height: 4)
            }
        }
    }
}

// MARK: - Header estándar de cada paso: barra de progreso arriba,
// título + subtítulo debajo.

struct OnboardingHeader: View {
    let pasoActual: Int
    let totalPasos: Int
    let titulo: String
    let subtitulo: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            OnboardingProgressBar(pasoActual: pasoActual, totalPasos: totalPasos)

            VStack(alignment: .leading, spacing: 8) {
                Text(titulo)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(ProgresaColor.primary)
                if let subtitulo {
                    Text(subtitulo)
                        .font(.subheadline)
                        .foregroundColor(ProgresaColor.textSecondary)
                }
            }
        }
    }
}

// MARK: - Selector grande +/- (edad, estatura, peso)

struct OnboardingStepperGrande: View {
    let valorTexto: String
    let unidadTexto: String
    let onDecrementar: () -> Void
    let onIncrementar: () -> Void

    var body: some View {
        HStack(spacing: 28) {
            botonCircular(icono: "minus", accion: onDecrementar)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(valorTexto)
                    .font(.system(size: 56, weight: .bold))
                    .foregroundColor(ProgresaColor.primary)
                Text(unidadTexto)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(ProgresaColor.textSecondary)
            }
            .frame(minWidth: 140)

            botonCircular(icono: "plus", accion: onIncrementar)
        }
        .frame(maxWidth: .infinity)
    }

    private func botonCircular(icono: String, accion: @escaping () -> Void) -> some View {
        Button(action: accion) {
            Image(systemName: icono)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(ProgresaColor.primary)
                .frame(width: 48, height: 48)
                .background(ProgresaColor.surface)
                .clipShape(Circle())
        }
    }
}

// MARK: - Toggle de unidad genérico (cm/ft, kg/lb) — mismo patrón visual
// que ya se usa en EjecucionRutinaView y EditarEquipoView.

struct OnboardingUnidadToggle: View {
    let opciones: [String]
    @Binding var seleccionada: String

    var body: some View {
        HStack(spacing: 0) {
            ForEach(opciones, id: \.self) { opcion in
                Button {
                    seleccionada = opcion
                } label: {
                    Text(opcion)
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundColor(seleccionada == opcion ? .white : ProgresaColor.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(seleccionada == opcion ? ProgresaColor.primary : Color.clear)
                        .cornerRadius(8)
                }
            }
        }
        .background(ProgresaColor.border.opacity(0.4))
        .cornerRadius(10)
    }
}

// MARK: - Tarjeta de opción tipo radio (experiencia, lugar de entrenamiento)

struct OnboardingRadioCard: View {
    let icono: String
    let titulo: String
    let seleccionado: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Color.white)
                    Image(systemName: icono)
                        .foregroundColor(ProgresaColor.primary)
                }
                .frame(width: 40, height: 40)

                Text(titulo)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ProgresaColor.primary)
                    .multilineTextAlignment(.leading)

                Spacer()

                ZStack {
                    Circle()
                        .stroke(seleccionado ? Color.clear : ProgresaColor.border, lineWidth: 1.5)
                        .frame(width: 24, height: 24)
                    if seleccionado {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 24, height: 24)
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(16)
            .background(seleccionado ? Color.orange.opacity(0.1) : ProgresaColor.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(seleccionado ? Color.orange : Color.clear, lineWidth: 1.5)
            )
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Leyenda pequeña bajo un input ("Pueden ser valores aproximados")

struct OnboardingLeyenda: View {
    let texto: String

    var body: some View {
        Text(texto)
            .font(.caption)
            .foregroundColor(ProgresaColor.textSecondary)
    }
}

// MARK: - Barra inferior estándar: botón "atrás" cuadrado + botón principal

struct OnboardingFooterNavegacion: View {
    let mostrarAtras: Bool
    let tituloBotonPrincipal: String
    let deshabilitado: Bool
    let cargando: Bool
    let onAtras: () -> Void
    let onPrincipal: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if mostrarAtras {
                Button(action: onAtras) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(ProgresaColor.primary)
                        .frame(width: 52, height: 52)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(ProgresaColor.border, lineWidth: 1)
                        )
                }
            }

            Button(action: onPrincipal) {
                HStack {
                    if cargando {
                        ProgressView().tint(.white)
                    } else {
                        Text(tituloBotonPrincipal)
                        Image(systemName: "arrow.right")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(ProgresaPrimaryButtonStyle())
            .disabled(deshabilitado || cargando)
        }
    }
}
