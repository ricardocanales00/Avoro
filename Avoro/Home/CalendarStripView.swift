import SwiftUI

struct CalendarStripView: View {
    let dias: [Date]
    let fechaSeleccionada: Date
    let etiquetaSemana: String
    let fechasCompletadas: Set<Date>
    let fechasConRutina: Set<Date>
    let onSeleccionar: (Date) -> Void
    let onSemanaAnterior: () -> Void
    let onSemanaSiguiente: () -> Void

    private let calendar = Calendar.current
    private let simbolosDia = ["D", "L", "M", "X", "J", "V", "S"]

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Button(action: onSemanaAnterior) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(ProgresaColor.textSecondary)
                }
                Spacer()
                Text(etiquetaSemana)
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundColor(ProgresaColor.textSecondary)
                Spacer()
                Button(action: onSemanaSiguiente) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(ProgresaColor.textSecondary)
                }
            }

            HStack(spacing: 4) {
                ForEach(Array(dias.enumerated()), id: \.offset) { index, fecha in
                    let seleccionado = calendar.isDate(fecha, inSameDayAs: fechaSeleccionada)
                    let esHoy = calendar.isDateInToday(fecha)

                    Button {
                        onSeleccionar(fecha)
                    } label: {
                        VStack(spacing: 4) {
                            Text(index < simbolosDia.count ? simbolosDia[index] : "")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(ProgresaColor.textSecondary)

                            Text(String(calendar.component(.day, from: fecha)))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(colorTexto(seleccionado: seleccionado, esHoy: esHoy))
                                .frame(width: 34, height: 34)
                                .background(seleccionado ? ProgresaColor.accent : Color.clear)
                                .clipShape(Circle())

                            Circle()
                                .fill(colorPunto(fecha: fecha) ?? .clear)
                                .frame(width: 5, height: 5)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 10)
        .background(ProgresaColor.background)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(ProgresaColor.border, lineWidth: 1)
        )
    }

    private func colorTexto(seleccionado: Bool, esHoy: Bool) -> Color {
        if seleccionado { return .white }
        if esHoy { return ProgresaColor.accent }
        return ProgresaColor.primary
    }

    /// Naranja/coral = ya se registró entrenamiento ese día.
    /// Gris = tiene rutina asignada pero todavía no hay registros.
    /// nil (sin punto) = ese día no tiene ninguna rutina asignada.
    private func colorPunto(fecha: Date) -> Color? {
        if fechasCompletadas.contains(where: { calendar.isDate($0, inSameDayAs: fecha) }) {
            return ProgresaColor.accent
        }
        if fechasConRutina.contains(where: { calendar.isDate($0, inSameDayAs: fecha) }) {
            return ProgresaColor.textSecondary.opacity(0.5)
        }
        return nil
    }
}

#Preview {
    CalendarStripView(
        dias: (0..<7).compactMap {
            Calendar.current.date(byAdding: .day, value: $0, to: Date())
        },
        fechaSeleccionada: Date(),
        etiquetaSemana: "Julio 2026",
        fechasCompletadas: [Calendar.current.startOfDay(for: Date())],
        fechasConRutina: [],
        onSeleccionar: { _ in },
        onSemanaAnterior: {},
        onSemanaSiguiente: {}
    )
    .padding()
}
