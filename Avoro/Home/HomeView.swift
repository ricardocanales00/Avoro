import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                } else if let error = viewModel.errorMessage {
                    errorState(mensaje: error)
                } else if viewModel.sinRutinaActiva {
                    sinRutinaState
                } else {
                    rutinaDeHoySection
                }

                verTodasMisRutinasCard
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
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.fechaHoyFormateada)
                .font(.subheadline)
                .foregroundColor(ProgresaColor.textSecondary)

            Text("Hola, \(viewModel.nombreUsuario.isEmpty ? "..." : viewModel.nombreUsuario)")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(ProgresaColor.primary)
        }
        .padding(.top, 12)
    }

    // MARK: - Rutina de hoy

    private var rutinaDeHoySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.footnote)
                Text("RUTINA DE HOY")
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

            if let dia = viewModel.diaDeHoy {
                diaCard(dia: dia)
            } else {
                Text("No hay ejercicios programados para hoy en tu rutina activa.")
                    .font(.subheadline)
                    .foregroundColor(ProgresaColor.textSecondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(ProgresaColor.surface)
                    .cornerRadius(16)
            }
        }
    }

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

            VStack(spacing: 10) {
                ForEach(dia.ejercicios.sorted { $0.orden < $1.orden }) { ejercicioDia in
                    EjercicioPreviewRow(ejercicioDia: ejercicioDia)
                }
            }

            NavigationLink {
                // TODO: conectar con la pantalla de Ejecución (Épica 4)
                // pasándole `dia` como parámetro.
                Text("Ejecución de rutina — siguiente pantalla")
            } label: {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Iniciar rutina")
                }
            }
            .buttonStyle(ProgresaPrimaryButtonStyle())
        }
        .padding(16)
        .background(ProgresaColor.surface)
        .cornerRadius(20)
    }

    // MARK: - Ver todas mis rutinas
    

    private var verTodasMisRutinasCard: some View {
        NavigationLink {
            // TODO: conectar con RutinaListView (Épica 2)
            Text("Listado de rutinas — siguiente pantalla")
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ver todas mis rutinas")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(ProgresaColor.primary)
                    Text("\(viewModel.totalRutinasGuardadas) rutina\(viewModel.totalRutinasGuardadas == 1 ? "" : "s") guardada\(viewModel.totalRutinasGuardadas == 1 ? "" : "s")")
                        .font(.footnote)
                        .foregroundColor(ProgresaColor.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(ProgresaColor.textSecondary)
            }
            .padding(16)
            .background(ProgresaColor.surface)
            .cornerRadius(16)
        }
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

                // Nota: el peso sugerido (ej. "60 kg" en el prototipo) viene
                // de la Épica 5 (sugerencia basada en histórico), que aún
                // no está construida. Por ahora solo mostramos series/reps
                // objetivo, que sí existen en ejercicio_dia.
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
        HomeView()
    }
}
