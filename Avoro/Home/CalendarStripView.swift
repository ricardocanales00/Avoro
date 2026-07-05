import SwiftUI

struct CalendarStripView: View {
    let dias: [Date]
    let fechaSeleccionada: Date
    let etiquetaSemana: String
    let fechasCompletadas: Set<Date>
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
                    let completado = fechasCompletadas.contains { calendar.isDate($0, inSameDayAs: fecha) }

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
                                .fill(ProgresaColor.accent)
                                .frame(width: 5, height: 5)
                                .opacity(completado ? 1 : 0)
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
}

#Preview {
    CalendarStripView(
        dias: (0..<7).compactMap {
            Calendar.current.date(byAdding: .day, value: $0, to: Date())
        },
        fechaSeleccionada: Date(),
        etiquetaSemana: "Julio 2026",
        fechasCompletadas: [Calendar.current.startOfDay(for: Date())],
        onSeleccionar: { _ in },
        onSemanaAnterior: {},
        onSemanaSiguiente: {}
    )
    .padding()
}
