import SwiftUI

// MARK: - Nombre de categoría para mostrar en UI

enum EquipoCategoria {
    static func nombreDisplay(_ raw: String) -> String {
        switch raw {
        case "peso_libre": return "Peso libre"
        case "maquina": return "Máquinas"
        case "cardio": return "Cardio"
        case "accesorio": return "Accesorios"
        default: return raw.capitalized
        }
    }
}

// MARK: - Pill individual de equipo

struct EquipoPill: View {
    let equipo: Equipo
    let seleccionado: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                if seleccionado {
                    Image(systemName: "checkmark")
                }
                Text(equipo.nombre)
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
        }
    }
}

// MARK: - Grid de categorías + pills, usado tal cual en EditarEquipoView
// y en el paso de equipo del wizard de onboarding.

struct EquipoSeleccionGrid: View {
    let categorias: [String]
    let equipoPorCategoria: (String) -> [Equipo]
    let estaSeleccionado: (Equipo) -> Bool
    let onToggle: (Equipo) -> Void

    var body: some View {
        ForEach(categorias, id: \.self) { categoria in
            VStack(alignment: .leading, spacing: 12) {
                Text(EquipoCategoria.nombreDisplay(categoria))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ProgresaColor.primary)

                FlowLayout(spacing: 10) {
                    ForEach(equipoPorCategoria(categoria)) { equipo in
                        EquipoPill(
                            equipo: equipo,
                            seleccionado: estaSeleccionado(equipo)
                        ) {
                            onToggle(equipo)
                        }
                    }
                }
            }
        }
    }
}

/// Layout de "wrap" simple (las pills pasan a la siguiente línea cuando no
/// caben) usando el protocolo `Layout` de iOS 16+ — coherente con el resto
/// del proyecto, que ya requiere iOS 16+ por Swift Charts en
/// `ProgresoEjercicioView`.
struct FlowLayout: Layout {
    var spacing: CGFloat = 10

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
