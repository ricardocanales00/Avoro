import SwiftUI
import Charts

struct ProgresoEjercicioView: View {
    @StateObject private var viewModel: ProgresoEjercicioViewModel
    @Environment(\.dismiss) private var dismiss

    let nombre: String
    let grupoMuscular: String
    let equipoNombre: String?
    let imagenUrl: String?
    let unidadSeleccionada: String

    init(
        ejercicioDiaId: UUID,
        nombre: String,
        grupoMuscular: String,
        equipoNombre: String?,
        imagenUrl: String?,
        unidadSeleccionada: String
    ) {
        _viewModel = StateObject(wrappedValue: ProgresoEjercicioViewModel(ejercicioDiaId: ejercicioDiaId))
        self.nombre = nombre
        self.grupoMuscular = grupoMuscular
        self.equipoNombre = equipoNombre
        self.imagenUrl = imagenUrl
        self.unidadSeleccionada = unidadSeleccionada
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerNavegacion
                encabezadoEjercicio

                // Estático por ahora, igual que en la vista de ejecución.
                PesoSugeridoCard(peso: 62.5, unidad: unidadSeleccionada, delta: 2.5)

                historicoSection
                informacionSection
            }
            .padding(20)
        }
        .background(ProgresaColor.background)
        .navigationBarHidden(true)
        .task {
            await viewModel.cargarHistorico(unidadDestino: unidadSeleccionada)
        }
    }

    // MARK: - Header

    private var headerNavegacion: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(ProgresaColor.primary)
            }

            Text("Progreso")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(ProgresaColor.primary)
                .padding(.leading, 4)

            Spacer()
        }
    }

    private var encabezadoEjercicio: some View {
        HStack(spacing: 14) {
            imagenEjercicio
                .frame(width: 56, height: 56)
                .background(ProgresaColor.border)
                .cornerRadius(14)
                .clipped()

            VStack(alignment: .leading, spacing: 2) {
                Text(nombre)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(ProgresaColor.primary)
                Text(grupoMuscular.capitalized)
                    .font(.subheadline)
                    .foregroundColor(ProgresaColor.textSecondary)
            }

            Spacer()
        }
    }

    @ViewBuilder
    private var imagenEjercicio: some View {
        if let urlString = imagenUrl, let url = URL(string: urlString) {
            AsyncImage(url: url) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color(ProgresaColor.border)
            }
        } else {
            ZStack {
                Color(ProgresaColor.border)
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundColor(ProgresaColor.textSecondary)
            }
        }
    }

    // MARK: - Histórico de peso

    private var historicoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Histórico de peso")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(ProgresaColor.primary)

                Spacer()

                if let delta = viewModel.deltaHistorico {
                    deltaBadge(delta)
                }
            }

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 180)
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundColor(.red)
            } else if viewModel.historial.isEmpty {
                Text("Todavía no hay suficientes registros para mostrar tu progreso en este ejercicio.")
                    .font(.footnote)
                    .foregroundColor(ProgresaColor.textSecondary)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(ProgresaColor.surface)
                    .cornerRadius(16)
            } else {
                graficaHistorico
                    .padding(16)
                    .background(ProgresaColor.surface)
                    .cornerRadius(16)
            }
        }
    }

    private func deltaBadge(_ delta: Double) -> some View {
        let esPositivo = delta >= 0
        return HStack(spacing: 2) {
            Image(systemName: esPositivo ? "arrow.up.right" : "arrow.down.right")
            Text("\(esPositivo ? "+" : "")\(formateado(delta)) \(unidadSeleccionada)")
        }
        .font(.subheadline)
        .fontWeight(.semibold)
        .foregroundColor(.orange)
    }

    private var graficaHistorico: some View {
        Chart(viewModel.historial) { punto in
            AreaMark(
                x: .value("Fecha", punto.fecha),
                y: .value("Peso", punto.peso)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [ProgresaColor.primary.opacity(0.15), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            LineMark(
                x: .value("Fecha", punto.fecha),
                y: .value("Peso", punto.peso)
            )
            .foregroundStyle(ProgresaColor.primary)
            .lineStyle(StrokeStyle(lineWidth: 2))

            PointMark(
                x: .value("Fecha", punto.fecha),
                y: .value("Peso", punto.peso)
            )
            .foregroundStyle(esUltimoPunto(punto) ? Color.orange : ProgresaColor.primary)
            .symbolSize(esUltimoPunto(punto) ? 90 : 40)
        }
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisValueLabel(format: .dateTime.day().month(.abbreviated).locale(Locale(identifier: "es")))
                    .font(.caption2)
                    .foregroundStyle(ProgresaColor.textSecondary)
            }
        }
        .frame(height: 180)
    }

    private func esUltimoPunto(_ punto: PuntoHistoricoPeso) -> Bool {
        punto.id == viewModel.historial.last?.id
    }

    private func formateado(_ valor: Double) -> String {
        valor.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", valor)
            : String(format: "%.1f", valor)
    }

    // MARK: - Información

    private var informacionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Información")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(ProgresaColor.primary)

            VStack(spacing: 0) {
                filaInformacion(titulo: "Grupo muscular", valor: grupoMuscular.capitalized)
                Divider().padding(.leading, 56)
                filaInformacion(titulo: "Equipo", valor: equipoNombre?.capitalized ?? "—")
            }
            .background(ProgresaColor.surface)
            .cornerRadius(16)
        }
    }

    private func filaInformacion(titulo: String, valor: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(ProgresaColor.border.opacity(0.5))
                    .frame(width: 32, height: 32)
                Image(systemName: "link")
                    .font(.footnote)
                    .foregroundColor(ProgresaColor.textSecondary)
            }

            Text(titulo)
                .font(.subheadline)
                .foregroundColor(ProgresaColor.textSecondary)

            Spacer()

            Text(valor)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(ProgresaColor.primary)
        }
        .padding(14)
    }
}
