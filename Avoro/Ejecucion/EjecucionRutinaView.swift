import SwiftUI
 
struct EjecucionRutinaView: View {
    @StateObject private var viewModel: EjecucionRutinaViewModel
    @Environment(\.dismiss) private var dismiss
 
    /// Índice del ejercicio que se está mostrando ahora mismo (paginación 1/2, 2/2, ...).
    /// Es un concepto puramente de navegación de la vista, por eso vive aquí y no en el ViewModel.
    @State private var indiceActual = 0
 
    /// Controla la navegación hacia la pantalla de "Progreso" del ejercicio actual.
    @State private var mostrarProgreso = false
 
    init(dia: DiaConEjercicios, unidadPreferida: String) {
        _viewModel = StateObject(wrappedValue: EjecucionRutinaViewModel(dia: dia, unidadPreferida: unidadPreferida))
    }
 
    private var ejercicioActualBinding: Binding<EjercicioEjecucionState>? {
        guard viewModel.ejercicios.indices.contains(indiceActual) else { return nil }
        return $viewModel.ejercicios[indiceActual]
    }
 
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerNavegacion
                progresoHeader
 
                if viewModel.rutinaTerminada {
                    banderaCompletada
                }
 
                if let binding = ejercicioActualBinding {
                    contenidoEjercicio(binding)
                }
            }
            .padding(20)
        }
        .background(ProgresaColor.background)
        .navigationBarHidden(true)
        .task {
            await viewModel.cargarProgresoDeHoy()
            await viewModel.cargarUltimosPesos()
        }
        .safeAreaInset(edge: .bottom) {
            bottomBar
        }
        .navigationDestination(isPresented: $mostrarProgreso) {
            if let estado = ejercicioActualBinding?.wrappedValue {
                ProgresoEjercicioView(
                    ejercicioDiaId: estado.ejercicioDia.id,
                    nombre: estado.ejercicioDia.ejercicio.nombre,
                    grupoMuscular: estado.ejercicioDia.ejercicio.grupoMuscular,
                    equipoNombre: estado.ejercicioDia.ejercicio.equipo?.nombre,
                    imagenUrl: estado.ejercicioDia.ejercicio.imagenUrl,
                    unidadSeleccionada: viewModel.unidadSeleccionada
                )
            }
        }
    }
 
    // MARK: - Header custom (chevron + título + contador de páginas)
 
    private var headerNavegacion: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(ProgresaColor.primary)
            }
 
            Spacer()
 
            Text(viewModel.dia.nombreDia)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(ProgresaColor.primary)
 
            Spacer()
 
            Text("\(min(indiceActual + 1, max(viewModel.total, 1)))/\(viewModel.total)")
                .font(.subheadline)
                .foregroundColor(ProgresaColor.textSecondary)
        }
    }
 
    private var progresoHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            ProgressView(value: Double(viewModel.completados), total: Double(max(viewModel.total, 1)))
                .tint(ProgresaColor.accent)
 
            Text("\(viewModel.completados) de \(viewModel.total) ejercicios completados")
                .font(.footnote)
                .foregroundColor(ProgresaColor.textSecondary)
        }
    }
 
    private var banderaCompletada: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(ProgresaColor.accent)
            Text("¡Rutina completada! Buen trabajo.")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(ProgresaColor.primary)
            Spacer()
        }
        .padding(14)
        .background(ProgresaColor.accent.opacity(0.12))
        .cornerRadius(14)
    }
 
    // MARK: - Contenido del ejercicio actual
 
    @ViewBuilder
    private func contenidoEjercicio(_ estado: Binding<EjercicioEjecucionState>) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            imagenEjercicio(estado.wrappedValue)
                .frame(height: 260)
                .frame(maxWidth: .infinity)
                .background(ProgresaColor.border)
                .cornerRadius(20)
                .clipped()
 
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(estado.wrappedValue.ejercicioDia.ejercicio.nombre)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(ProgresaColor.primary)
                    Text(estado.wrappedValue.ejercicioDia.ejercicio.grupoMuscular.capitalized)
                        .font(.subheadline)
                        .foregroundColor(ProgresaColor.textSecondary)
                }
 
                Spacer()
 
                Button {
                    mostrarProgreso = true
                } label: {
                    Label("Progreso", systemImage: "chart.line.uptrend.xyaxis")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .buttonStyle(ProgresaOutlineButtonStyle())
            }
 
            // Estático por ahora — más adelante esto vendrá de un modelo de ML
            // que analice el histórico de RegistroEntrenamiento del usuario.
            PesoSugeridoCard(peso: 62.5, unidad: viewModel.unidadSeleccionada, delta: 2.5)
 
            SeriesCard(estado: estado, viewModel: viewModel)
        }
    }
 
    @ViewBuilder
    private func imagenEjercicio(_ estado: EjercicioEjecucionState) -> some View {
        if let urlString = estado.ejercicioDia.ejercicio.imagenUrl, let url = URL(string: urlString) {
            AsyncImage(url: url) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color(ProgresaColor.border)
            }
        } else {
            ZStack {
                Color(ProgresaColor.border)
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 40))
                    .foregroundColor(ProgresaColor.textSecondary)
            }
        }
    }
 
    // MARK: - Barra inferior (error + acciones)
 
    private var bottomBar: some View {
        VStack(spacing: 10) {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundColor(.red)
            }
 
            HStack(spacing: 12) {
                Button {
                    // TODO: lógica de sustitución de ejercicio.
                } label: {
                    Label("Sustituir", systemImage: "arrow.triangle.2.circlepath")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ProgresaOutlineButtonStyle())
 
                Button {
                    avanzarSiguienteEjercicio()
                } label: {
                    Text(esUltimoEjercicio ? "Terminar" : "Siguiente ejercicio")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ProgresaPrimaryButtonStyle())
            }
        }
        .padding(16)
        .background(ProgresaColor.surface)
    }
 
    private var esUltimoEjercicio: Bool {
        indiceActual >= viewModel.ejercicios.count - 1
    }
 
    private func avanzarSiguienteEjercicio() {
        guard let estado = ejercicioActualBinding?.wrappedValue else { return }
 
        if estado.completado {
            irAlSiguiente()
            return
        }
 
        Task {
            await viewModel.guardarSeries(paraEjercicioConId: estado.id)
            if viewModel.errorMessage == nil {
                irAlSiguiente()
            }
        }
    }
 
    private func irAlSiguiente() {
        if esUltimoEjercicio {
            dismiss()
        } else {
            indiceActual += 1
        }
    }
}
 
// MARK: - Tarjeta de series (tabla Serie / Reps / Peso / Ok)
 
private struct SeriesCard: View {
    @Binding var estado: EjercicioEjecucionState
    @ObservedObject var viewModel: EjecucionRutinaViewModel
 
    private var unidad: String { viewModel.unidadSeleccionada }
 
    private var seriesCompletas: Int {
        estado.series.filter { !$0.repeticiones.isEmpty && !$0.peso.isEmpty }.count
    }
 
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("SERIES · \(seriesCompletas)/\(estado.series.count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(ProgresaColor.textSecondary)
 
                Spacer()
 
                unidadToggle
            }
 
            if estado.completado {
                resumenGuardado
            } else {
                tablaSeries
            }
        }
        .padding(16)
        .background(ProgresaColor.surface)
        .cornerRadius(20)
    }
 
    private var unidadToggle: some View {
        HStack(spacing: 0) {
            botonUnidad("kg")
            botonUnidad("lb")
        }
        .background(ProgresaColor.border.opacity(0.4))
        .cornerRadius(10)
    }
 
    private func botonUnidad(_ valor: String) -> some View {
        Button {
            viewModel.unidadSeleccionada = valor
        } label: {
            Text(valor)
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundColor(unidad == valor ? .white : ProgresaColor.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(unidad == valor ? ProgresaColor.primary : Color.clear)
                .cornerRadius(8)
        }
    }
 
    private var tablaSeries: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Serie").frame(width: 44, alignment: .leading)
                Text("Reps").frame(maxWidth: .infinity, alignment: .leading)
                Text("Peso (\(unidad))").frame(maxWidth: .infinity, alignment: .leading)
                Text("Ok").frame(width: 32, alignment: .center)
            }
            .font(.footnote)
            .foregroundColor(ProgresaColor.textSecondary)
 
            ForEach($estado.series) { $serie in
                HStack(spacing: 8) {
                    Text("\(serie.numeroSerie)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(ProgresaColor.primary)
                        .frame(width: 44, alignment: .leading)
 
                    // Placeholder = repeticiones objetivo configuradas en la rutina.
                    TextField(repsPlaceholder, text: $serie.repeticiones)
                        .keyboardType(.numberPad)
                        .textFieldStyle(ProgresaTextFieldStyle())
 
                    // Placeholder = último peso registrado para esta serie,
                    // convertido a la unidad seleccionada. Si no hay historial,
                    // cae de vuelta a "Peso (kg)"/"Peso (lb)".
                    TextField(pesoPlaceholder(for: serie), text: $serie.peso)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(ProgresaTextFieldStyle())
 
                    // Decorativo: se rellena cuando la fila tiene datos válidos.
                    // El guardado real sigue siendo todo-o-nada vía guardarSeries().
                    Image(systemName: filaValida(serie) ? "checkmark.circle.fill" : "checkmark.circle")
                        .foregroundColor(filaValida(serie) ? ProgresaColor.accent : ProgresaColor.border)
                        .frame(width: 32)
                }
            }
        }
    }
 
    // NOTA: asumo que EjercicioDiaConEjercicio expone `repeticionesObjetivo`
    // (igual que ya expone `seriesObjetivo`), reflejando la columna
    // `repeticiones_objetivo` de `ejercicio_dia` en tu esquema SQL.
    private var repsPlaceholder: String {
        String(estado.ejercicioDia.repeticionesObjetivo)
    }
 
    private func pesoPlaceholder(for serie: SerieCaptura) -> String {
        guard let sugerido = viewModel.pesoSugerido(
            paraEjercicioDiaId: estado.id,
            numeroSerie: serie.numeroSerie
        ) else {
            return "Peso (\(unidad))"
        }
        return formatearPeso(sugerido)
    }
 
    private func filaValida(_ serie: SerieCaptura) -> Bool {
        !serie.repeticiones.isEmpty && !serie.peso.isEmpty
    }
 
    private var resumenGuardado: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(estado.registrosGuardadosHoy.sorted { $0.numeroSerie < $1.numeroSerie }) { registro in
                Text("Serie \(registro.numeroSerie): \(registro.repeticionesReales) reps · \(formatearPeso(registro.peso)) \(registro.unidad)")
                    .font(.footnote)
                    .foregroundColor(ProgresaColor.textSecondary)
            }
        }
    }
 
    private func formatearPeso(_ peso: Double) -> String {
        peso.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", peso)
            : String(format: "%.1f", peso)
    }
}
 
 
