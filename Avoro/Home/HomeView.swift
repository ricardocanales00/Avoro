import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: Int
    @StateObject private var viewModel = HomeViewModel()
    @State private var mostrarModoEntrenador = false

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    CalendarStripView(
                        dias: viewModel.diasDeLaSemana,
                        fechaSeleccionada: viewModel.fechaSeleccionada,
                        etiquetaSemana: viewModel.etiquetaSemana,
                        fechasCompletadas: viewModel.fechasCompletadas,
                        fechasConRutina: viewModel.fechasConRutina,
                        onSeleccionar: { fecha in
                            viewModel.seleccionarFecha(fecha)
                        },
                        onSemanaAnterior: {
                            viewModel.cambiarSemana(-1)
                        },
                        onSemanaSiguiente: {
                            viewModel.cambiarSemana(1)
                        }
                    )

                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    } else if let error = viewModel.errorMessage {
                        errorState(mensaje: error)
                    } else if viewModel.sinRutinaActiva {
                        sinRutinaState
                    } else if viewModel.sinEjerciciosEsteDia {
                        sinEjerciciosEsteDiaState
                    } else {
                        if viewModel.diaSeleccionadoCompletado {
                            banderaCompletada
                        }
                        rutinaDelDiaSection
                    }

                    appsSection
                }
                .padding(20)
            }
            .background(ProgresaColor.background)
            .refreshable {
                await viewModel.cargarDatos()
            }
            .task {
                await viewModel.cargarDatos()
            }
            .navigationDestination(isPresented: $mostrarModoEntrenador) {
                ModoEntrenadorInicioView(
                    diaActual: viewModel.diaSeleccionado,
                    unidadPreferida: viewModel.unidadPreferida,
                    fechaSeleccionada: viewModel.fechaSeleccionada
                )
            }

            // Cubre el status bar: sin esto, el header ("Hola, ...") puede
            // scrollear por debajo del reloj/íconos del sistema porque esta
            // pantalla no tiene navigation bar visible que reserve ese
            // espacio de forma opaca.
            //
            // NOTA: se usa una altura fija (60pt) en vez de leer
            // `GeometryProxy.safeAreaInsets.top` con un GeometryReader de
            // altura 0 — ese truco resultó poco confiable aquí (reportaba
            // 0 en vez del inset real). 60pt cubre con margen el status
            // bar de cualquier iPhone actual (con o sin Dynamic Island);
            // como es del mismo color que el fondo, cubrir de más no se
            // nota.
            Color(ProgresaColor.background)
                .frame(height: 60)
                .ignoresSafeArea(edges: .top)
        }
    }

    // MARK: - Apps (sin funcionalidad todavía)

    private var appsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Apps")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(ProgresaColor.primary)

            VStack(spacing: 0) {
                appRow(nombre: "Spotify", colorIcono: Color(red: 0.11, green: 0.84, blue: 0.38), estado: .vinculado)
                Divider().padding(.leading, 66)
                appRow(nombre: "Apple Music", colorIcono: Color(red: 0.98, green: 0.14, blue: 0.23), estado: .conectar)
            }
            .background(ProgresaColor.surface)
            .cornerRadius(16)
        }
    }

    private enum EstadoConexionApp {
        case vinculado
        case conectar
    }

    private func appRow(nombre: String, colorIcono: Color, estado: EstadoConexionApp) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(colorIcono)
                Image(systemName: "music.note")
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .bold))
            }
            .frame(width: 40, height: 40)

            Text(nombre)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(ProgresaColor.primary)

            Spacer()

            Button {
                // TODO: integración real pendiente — sin acción por ahora.
            } label: {
                switch estado {
                case .vinculado:
                    Label("Vinculado", systemImage: "checkmark")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(ProgresaColor.accent)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                case .conectar:
                    Text("Conectar")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(ProgresaColor.primary)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                }
            }
        }
        .padding(14)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.fechaSeleccionadaFormateada)
                .font(.subheadline)
                .foregroundColor(ProgresaColor.textSecondary)

            Text("Hola, \(viewModel.nombreUsuario.isEmpty ? "..." : viewModel.nombreUsuario)")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(ProgresaColor.primary)
        }
        .padding(.top, 12)
    }

    // MARK: - Rutina del día seleccionado

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

    private var rutinaDelDiaSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.footnote)
                Text("RUTINA DE ESTE DÍA")
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
                if !viewModel.nombreBloqueRutina.isEmpty {
                    Text(viewModel.nombreBloqueRutina)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }
            .foregroundColor(ProgresaColor.textSecondary)

            if let dia = viewModel.diaSeleccionado {
                diaCard(dia: dia)
            }
        }
    }

    /// Alto aproximado para mostrar 2 filas de `EjercicioPreviewRow` — el
    /// resto de la lista queda accesible con scroll interno, sin empujar
    /// los botones de acción hacia abajo cuando la rutina tiene muchos
    /// ejercicios. Es un valor "a ojo" (igual que los 60pt del status bar
    /// más abajo), no calculado dinámicamente por altura real de fila,
    /// porque el nombre del ejercicio puede envolver a 1 o 2 líneas.
    private let alturaListaEjercicios: CGFloat = 172

    private func diaCard(dia: DiaConEjercicios) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(dia.nombreDia)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(ProgresaColor.primary)
                Text("\(dia.ejercicios.count) ejercicio\(dia.ejercicios.count == 1 ? "" : "s") previstos")
                    .font(.footnote)
                    .foregroundColor(ProgresaColor.textSecondary)
            }

            ScrollView(showsIndicators: true) {
                VStack(spacing: 10) {
                    ForEach(dia.ejercicios.sorted { $0.orden < $1.orden }) { ejercicioDia in
                        EjercicioPreviewRow(ejercicioDia: ejercicioDia)
                    }
                }
            }
            .frame(height: alturaListaEjercicios)

            VStack(spacing: 10) {
                Button {
                    mostrarModoEntrenador = true
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Modo Entrenador")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(ProgresaColor.primary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(ProgresaColor.accent, lineWidth: 2)
                    )
                    .cornerRadius(12)
                }

                NavigationLink {
                    EjecucionRutinaView(dia: dia, unidadPreferida: viewModel.unidadPreferida, fecha: viewModel.fechaSeleccionada)
                } label: {
                    Text("Iniciar rutina")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ProgresaOutlineButtonStyle())
            }
        }
        .padding(16)
        .background(ProgresaColor.surface)
        .cornerRadius(20)
    }

    // MARK: - Estados vacíos / error

    private var sinRutinaState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Aún no tienes una rutina activa")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(ProgresaColor.primary)
            Text("Crea tu primera rutina para empezar a registrar tus entrenamientos.")
                .font(.footnote)
                .foregroundColor(ProgresaColor.textSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ProgresaColor.surface)
        .cornerRadius(16)
    }

    private var sinEjerciciosEsteDiaState: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(ProgresaColor.background)
                    .frame(width: 56, height: 56)
                Image(systemName: "moon.zzz")
                    .font(.system(size: 22))
                    .foregroundColor(ProgresaColor.textSecondary)
            }

            Text("Día de descanso")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(ProgresaColor.primary)

            Text("No hay rutina prevista para este día. Aprovecha para recuperar.")
                .font(.footnote)
                .foregroundColor(ProgresaColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 20)
        .background(ProgresaColor.surface)
        .cornerRadius(20)
    }

    private func errorState(mensaje: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(mensaje)
                .font(.footnote)
                .foregroundColor(.red)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ProgresaColor.surface)
        .cornerRadius(16)
    }
}

// MARK: - Fila de ejercicio dentro de la card del día

private struct EjercicioPreviewRow: View {
    let ejercicioDia: EjercicioDiaConEjercicio

    var body: some View {
        HStack(spacing: 12) {
            imagen
                .frame(width: 48, height: 48)
                .background(ProgresaColor.border)
                .cornerRadius(10)
                .clipped()

            VStack(alignment: .leading, spacing: 2) {
                Text(ejercicioDia.ejercicio.nombre)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(ProgresaColor.primary)

                Text("\(ejercicioDia.seriesObjetivo) series · \(ejercicioDia.repeticionesObjetivo) reps")
                    .font(.footnote)
                    .foregroundColor(ProgresaColor.textSecondary)
            }

            Spacer()
        }
        .padding(10)
        .background(ProgresaColor.background)
        .cornerRadius(12)
    }

    @ViewBuilder
    private var imagen: some View {
        if let urlString = ejercicioDia.ejercicio.imagenUrl, let url = URL(string: urlString) {
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
}

#Preview {
    NavigationStack {
        HomeView(selectedTab: .constant(0))
    }
}
