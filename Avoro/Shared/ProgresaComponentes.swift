import SwiftUI

// MARK: - Tarjeta de peso sugerido (estática por ahora)
// Más adelante esto vendrá de un modelo de ML que analice el histórico
// de RegistroEntrenamiento del usuario. Por ahora es un valor fijo.

struct PesoSugeridoCard: View {
    let peso: Double
    let unidad: String
    let delta: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "scope")
                    .foregroundColor(.orange)
                Text("PESO SUGERIDO PARA HOY")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(formateado(peso)) \(unidad)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(ProgresaColor.primary)

                HStack(spacing: 2) {
                    Image(systemName: "arrow.up.right")
                    Text("+\(formateado(delta)) \(unidad)")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.orange)
            }

            Text("Vas progresando de forma constante. ¡Sube el peso hoy!")
                .font(.footnote)
                .foregroundColor(ProgresaColor.textSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.12))
        .cornerRadius(16)
    }

    private func formateado(_ valor: Double) -> String {
        valor.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", valor)
            : String(format: "%.1f", valor)
    }
}

// MARK: - Estilo de botón outline (para "Sustituir" y "Progreso")
// Si ya tienes un ProgresaSecondaryButtonStyle o similar en tu proyecto, usa ese en su lugar.

struct ProgresaOutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(ProgresaColor.primary)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(ProgresaColor.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(ProgresaColor.border, lineWidth: 1)
            )
            .cornerRadius(14)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
