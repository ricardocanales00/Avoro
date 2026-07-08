import SwiftUI

struct EditarEquipoView: View {
    @StateObject private var viewModel: EditarEquipoViewModel
    @Environment(\.dismiss) private var dismiss
    let onGuardado: () -> Void

    init(usuarioId: UUID, onGuardado: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: EditarEquipoViewModel(usuarioId: usuarioId))
        self.onGuardado = onGuardado
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            if viewModel.isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        buscador

                        ForEach(viewModel.categorias, id: \.self) { categoria in
                            seccionCategoria(categoria)
                        }
                    }
                    .padding(20)
                }
            }

            footer
        }
        .background(ProgresaColor.background)
        .navigationBarHidden(true)
        .task {
            await viewModel.cargar()
        }
        .onChange(of: viewModel.guardadoConExito) { exito in
            guard exito else { return }
            onGuardado()
            dismiss()
        }
    }

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(ProgresaColor.primary)
            }
            Spacer()
            Text("¿Qué equipo tienes?")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(ProgresaColor.primary)
            Spacer()
            // Espaciador simétrico para centrar el título con el chevron.
            Image(systemName: "chevron.left").opacity(0)
        }
        .padding(16)
    }

    private var buscador: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(ProgresaColor.textSecondary)
            TextField("Buscar equipo...", text: $viewModel.busqueda)
        }
        .padding(12)
        .background(ProgresaColor.surface)
        .cornerRadius(12)
    }

    private func seccionCategoria(_ categoria: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(nombreCategoria(categoria))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(ProgresaColor.primary)

            FlowLayout(spacing: 10) {
                ForEach(viewModel.equipoEnCategoria(categoria)) { equipo in
                    pillEquipo(equipo)
                }
            }
        }
    }

    private func pillEquipo(_ equipo: Equipo) -> some View {
        let seleccionado = viewModel.seleccionados.contains(equipo.id)
        return Button {
            viewModel.toggle(equipo)
        } label: {
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

    private func nombreCategoria(_ raw: String) -> String {
        switch raw {
        case "peso_libre": return "Peso libre"
        case "maquina": return "Máquinas"
        case "cardio": return "Cardio"
        case "accesorio": return "Accesorios"
        default: return raw.capitalized
        }
    }

    private var footer: some View {
        VStack(spacing: 10) {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundColor(.red)
            }

            Text("\(viewModel.seleccionados.count) seleccionados")
                .font(.footnote)
                .foregroundColor(ProgresaColor.textSecondary)

            Button {
                Task { await viewModel.guardar() }
            } label: {
                if viewModel.isSaving {
                    ProgressView().tint(.white)
                } else {
                    Text("Guardar")
                }
            }
            .buttonStyle(ProgresaPrimaryButtonStyle())
            .disabled(viewModel.isSaving)
        }
        .padding(16)
        .background(ProgresaColor.surface)
    }
}

/// Layout de "wrap" simple (las pills pasan a la siguiente línea cuando no
/// caben) usando el protocolo `Layout` de iOS 16+ — coherente con el resto
/// del proyecto, que ya requiere iOS 16+ por Swift Charts en
/// `ProgresoEjercicioView`. Se reutiliza también en `EditarEjerciciosView`
/// si hace falta un layout de tags ahí.
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
