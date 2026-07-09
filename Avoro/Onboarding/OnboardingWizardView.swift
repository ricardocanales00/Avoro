import SwiftUI

/// Punto de entrada del wizard. Quien lo presente (típicamente el root de
/// navegación después del login, cuando `perfiles.onboarding_completado`
/// es `false`) debe reaccionar a `onFinalizado` para regresar a la app
/// normal — este view no sabe nada de esa navegación externa.
struct OnboardingWizardView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    let onFinalizado: () -> Void

    var body: some View {
        Group {
            if viewModel.datosBasicosGuardados {
                OnboardingEquipoStepView(viewModel: viewModel, onFinalizado: onFinalizado)
            } else {
                pasoBasico
            }
        }
        .onChange(of: viewModel.onboardingCompletado) { completado in
            if completado { onFinalizado() }
        }
    }

    @ViewBuilder
    private var pasoBasico: some View {
        switch viewModel.pasoActual {
        case 0: OnboardingEdadView(viewModel: viewModel)
        case 1: OnboardingEstaturaView(viewModel: viewModel)
        case 2: OnboardingPesoView(viewModel: viewModel)
        case 3: OnboardingExperienciaView(viewModel: viewModel)
        default: OnboardingLugarView(viewModel: viewModel)
        }
    }
}

// MARK: - Paso 1: Edad

struct OnboardingEdadView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            OnboardingHeader(
                pasoActual: viewModel.pasoActual,
                totalPasos: viewModel.totalPasos,
                titulo: "¿Cuántos\naños tienes?",
                subtitulo: "Nos ayuda a ajustar volumen e intensidad."
            )

            Spacer()

            OnboardingStepperGrande(
                valorTexto: "\(viewModel.edad)",
                unidadTexto: "años",
                onDecrementar: { viewModel.edad = max(10, viewModel.edad - 1) },
                onIncrementar: { viewModel.edad = min(100, viewModel.edad + 1) }
            )

            Spacer()
            Spacer()

            OnboardingFooterNavegacion(
                mostrarAtras: false,
                tituloBotonPrincipal: "Continuar",
                deshabilitado: false,
                cargando: false,
                onAtras: {},
                onPrincipal: { viewModel.avanzar() }
            )
        }
        .padding(20)
        .background(ProgresaColor.background)
    }
}

// MARK: - Paso 2: Estatura

struct OnboardingEstaturaView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                OnboardingHeader(
                    pasoActual: viewModel.pasoActual,
                    totalPasos: viewModel.totalPasos,
                    titulo: "¿Cuánto mides?",
                    subtitulo: nil
                )
                Spacer()
            }

            HStack {
                Spacer()
                OnboardingUnidadToggle(opciones: ["cm", "ft"], seleccionada: $viewModel.unidadEstatura)
            }
            .padding(.top, 12)

            Spacer()

            VStack(spacing: 10) {
                OnboardingStepperGrande(
                    valorTexto: valorMostrado,
                    unidadTexto: viewModel.unidadEstatura == "cm" ? "cm" : "",
                    onDecrementar: { viewModel.decrementarEstatura() },
                    onIncrementar: { viewModel.incrementarEstatura() }
                )
                OnboardingLeyenda(texto: "Pueden ser valores aproximados")
            }

            Spacer()
            Spacer()

            OnboardingFooterNavegacion(
                mostrarAtras: true,
                tituloBotonPrincipal: "Continuar",
                deshabilitado: false,
                cargando: false,
                onAtras: { viewModel.retroceder() },
                onPrincipal: { viewModel.avanzar() }
            )
        }
        .padding(20)
        .background(ProgresaColor.background)
    }

    private var valorMostrado: String {
        if viewModel.unidadEstatura == "cm" {
            return "\(Int(viewModel.estaturaCm.rounded()))"
        }
        let (pies, pulgadas) = viewModel.estaturaPiesPulgadas
        return "\(pies)'\(pulgadas)\""
    }
}

// MARK: - Paso 3: Peso actual

struct OnboardingPesoView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            OnboardingHeader(
                pasoActual: viewModel.pasoActual,
                totalPasos: viewModel.totalPasos,
                titulo: "¿Cuál es tu\npeso actual?",
                subtitulo: "Podrás verlo progresar con el tiempo."
            )

            HStack {
                Spacer()
                OnboardingUnidadToggle(
                    opciones: ["kg", "lb"],
                    seleccionada: Binding(
                        get: { viewModel.unidadPeso },
                        set: { viewModel.cambiarUnidadPeso($0) }
                    )
                )
            }
            .padding(.top, 12)

            Spacer()

            VStack(spacing: 10) {
                OnboardingStepperGrande(
                    valorTexto: "\(Int(viewModel.pesoActual.rounded()))",
                    unidadTexto: viewModel.unidadPeso,
                    onDecrementar: { viewModel.decrementarPeso() },
                    onIncrementar: { viewModel.incrementarPeso() }
                )
                OnboardingLeyenda(texto: "Pueden ser valores aproximados")
            }

            Spacer()
            Spacer()

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .padding(.bottom, 8)
            }

            OnboardingFooterNavegacion(
                mostrarAtras: true,
                tituloBotonPrincipal: "Continuar",
                deshabilitado: false,
                cargando: false,
                onAtras: { viewModel.retroceder() },
                onPrincipal: { viewModel.avanzar() }
            )
        }
        .padding(20)
        .background(ProgresaColor.background)
    }
}

// MARK: - Paso 4: Experiencia

struct OnboardingExperienciaView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            OnboardingHeader(
                pasoActual: viewModel.pasoActual,
                totalPasos: viewModel.totalPasos,
                titulo: "¿Cómo describirías\ntu experiencia?",
                subtitulo: nil
            )
            .padding(.bottom, 24)

            VStack(spacing: 12) {
                ForEach(ExperienciaNivel.allCases, id: \.self) { nivel in
                    OnboardingRadioCard(
                        icono: nivel.icono,
                        titulo: nivel.titulo,
                        seleccionado: viewModel.experiencia == nivel
                    ) {
                        viewModel.experiencia = nivel
                    }
                }
            }

            Spacer()

            OnboardingFooterNavegacion(
                mostrarAtras: true,
                tituloBotonPrincipal: "Continuar",
                deshabilitado: viewModel.experiencia == nil,
                cargando: false,
                onAtras: { viewModel.retroceder() },
                onPrincipal: { viewModel.avanzar() }
            )
        }
        .padding(20)
        .background(ProgresaColor.background)
    }
}

// MARK: - Paso 5: Dónde entrenas (último paso "básico" — al continuar,
// aquí es donde se guarda todo en Supabase antes de pasar a equipo).

struct OnboardingLugarView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            OnboardingHeader(
                pasoActual: viewModel.pasoActual,
                totalPasos: viewModel.totalPasos,
                titulo: "¿Dónde entrenas?",
                subtitulo: nil
            )
            .padding(.bottom, 24)

            VStack(spacing: 12) {
                ForEach(LugarEntrenamiento.allCases, id: \.self) { lugar in
                    OnboardingRadioCard(
                        icono: lugar.icono,
                        titulo: lugar.titulo,
                        seleccionado: viewModel.lugarEntrenamiento == lugar
                    ) {
                        viewModel.lugarEntrenamiento = lugar
                    }
                }
            }

            Spacer()

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .padding(.bottom, 8)
            }

            // Este es el único botón "Continuar" de los 5 pasos básicos que
            // dispara un guardado real en Supabase — los anteriores solo
            // avanzan el índice local. Al terminar, `guardarDatosBasicos()`
            // avanza automáticamente al paso de equipo.
            OnboardingFooterNavegacion(
                mostrarAtras: true,
                tituloBotonPrincipal: "Continuar",
                deshabilitado: viewModel.lugarEntrenamiento == nil,
                cargando: viewModel.isSaving,
                onAtras: { viewModel.retroceder() },
                onPrincipal: { Task { await viewModel.guardarDatosBasicos() } }
            )
        }
        .padding(20)
        .background(ProgresaColor.background)
    }
}
