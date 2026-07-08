import Foundation
import Combine
import Supabase

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var nombreUsuario = ""
    @Published var unidadPreferida = "kg"
    @Published var isLoading = false
    @Published var errorMessage: String?

    /// TODAS las rutinas del usuario (no solo la marcada `activa`), cada
    /// una con sus días y ejercicios anidados. Se piden una sola vez;
    /// navegar el calendario NO vuelve a pedirle nada al servidor, solo
    /// recalcula en Swift qué rutina y qué día corresponden a la fecha.
    @Published private(set) var rutinas: [RutinaConDias] = []
    @Published private(set) var rutinaMostrada: RutinaConDias?
    @Published private(set) var diaSeleccionado: DiaConEjercicios?
    @Published private(set) var fechaSeleccionada = Calendar.current.startOfDay(for: Date())
    @Published private(set) var fechasCompletadas: Set<Date> = []

    private let rutinaService = RutinaService()
    private let registroService = RegistroService()
    private let client = SupabaseService.shared.client

    private static let formatoFecha: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    /// Calendario fijo en domingo-primero (D L M X J V S), sin importar
    /// la configuración regional del dispositivo.
    private var calendarioSemana: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "es_MX")
        cal.firstWeekday = 1
        return cal
    }

    /// Los 7 días de la semana que contiene `fechaSeleccionada` — cambia
    /// junto con la selección, lo que permite navegar semanas completas.
    var diasDeLaSemana: [Date] {
        guard let inicioSemana = calendarioSemana.dateInterval(of: .weekOfYear, for: fechaSeleccionada)?.start else {
            return []
        }
        return (0..<7).compactMap { calendarioSemana.date(byAdding: .day, value: $0, to: inicioSemana) }
    }

    /// Etiqueta arriba del strip, ej. "Julio 2026" o "Junio – Julio 2026"
    /// si la semana visible cruza de un mes a otro.
    var etiquetaSemana: String {
        guard let primero = diasDeLaSemana.first, let ultimo = diasDeLaSemana.last else { return "" }

        let formatterMes = DateFormatter()
        formatterMes.locale = Locale(identifier: "es_MX")
        formatterMes.dateFormat = "MMMM"

        let formatterAnio = DateFormatter()
        formatterAnio.dateFormat = "yyyy"

        let mesInicio = formatterMes.string(from: primero).capitalized
        let mesFin = formatterMes.string(from: ultimo).capitalized
        let anio = formatterAnio.string(from: ultimo)

        return mesInicio == mesFin ? "\(mesInicio) \(anio)" : "\(mesInicio) – \(mesFin) \(anio)"
    }

    var nombreBloqueRutina: String { rutinaMostrada?.nombre ?? "" }
    var totalRutinasGuardadas: Int { rutinas.count }
    var sinRutinaActiva: Bool { rutinas.isEmpty }

    /// true si el día actualmente seleccionado ya tiene todos sus
    /// ejercicios registrados. Reutiliza `fechasCompletadas` (ya calculado
    /// por `actualizarCompletados()`), no pide nada nuevo al servidor.
    var diaSeleccionadoCompletado: Bool {
        fechasCompletadas.contains(Calendar.current.startOfDay(for: fechaSeleccionada))
    }

    /// Días de la semana visible que SÍ tienen una rutina asignada (con o
    /// sin registros todavía) — para el punto gris del calendario. No pide
    /// nada al servidor: se calcula sobre `rutinas`, ya cargadas.
    var fechasConRutina: Set<Date> {
        let calendar = Calendar.current
        var resultado: Set<Date> = []
        for fecha in diasDeLaSemana {
            if let rutina = rutinaParaFecha(fecha), diaParaFecha(fecha, rutina: rutina) != nil {
                resultado.insert(calendar.startOfDay(for: fecha))
            }
        }
        return resultado
    }

    /// true cuando SÍ tienes rutinas guardadas, pero ninguna cubre la
    /// fecha elegida (hueco entre rutinas, antes de la primera, después
    /// de la última, o una rutina sin días).
    var sinEjerciciosEsteDia: Bool { !rutinas.isEmpty && diaSeleccionado == nil }

    var fechaSeleccionadaFormateada: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_MX")
        formatter.dateFormat = "EEEE, d 'de' MMMM"
        return formatter.string(from: fechaSeleccionada).capitalized(with: Locale(identifier: "es_MX"))
    }

    func cargarDatos() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        guard let usuarioId = client.auth.currentUser?.id else {
            errorMessage = "No se encontró tu sesión. Intenta iniciar sesión de nuevo."
            return
        }

        do {
            async let perfilTask = fetchPerfil(usuarioId)
            async let rutinasTask = rutinaService.fetchTodasConDias(usuarioId: usuarioId)

            let perfil = try await perfilTask
            nombreUsuario = perfil.nombre
            unidadPreferida = perfil.unidadPreferida
            rutinas = try await rutinasTask

            actualizarDiaSeleccionado()
            await actualizarCompletados()
        } catch {
            errorMessage = "No se pudieron cargar tus rutinas. Desliza hacia abajo para reintentar."
        }
    }

    func seleccionarFecha(_ fecha: Date) {
        fechaSeleccionada = Calendar.current.startOfDay(for: fecha)
        actualizarDiaSeleccionado()
        Task { await actualizarCompletados() }
    }

    /// Mueve la fecha seleccionada 7 días hacia atrás o adelante, lo que
    /// automáticamente desliza todo el strip a la semana anterior/siguiente
    /// porque `diasDeLaSemana` depende de `fechaSeleccionada`.
    func cambiarSemana(_ delta: Int) {
        guard let nuevaFecha = Calendar.current.date(byAdding: .day, value: 7 * delta, to: fechaSeleccionada) else { return }
        seleccionarFecha(nuevaFecha)
    }

    /// Revisa, para cada día visible en el strip, si la rutina asignada a
    /// esa fecha quedó completa (todas sus series registradas con esa
    /// fecha exacta) — así se puede pintar el punto de completado.
    private func actualizarCompletados() async {
        let calendar = Calendar.current
        guard let primero = diasDeLaSemana.first, let ultimo = diasDeLaSemana.last else {
            fechasCompletadas = []
            return
        }
        guard let usuarioId = client.auth.currentUser?.id else { return }

        do {
            let desde = HomeViewModel.formatoFecha.string(from: primero)
            let hasta = HomeViewModel.formatoFecha.string(from: ultimo)
            let registros = try await registroService.fetchRegistrosEntreFechas(
                usuarioId: usuarioId, desde: desde, hasta: hasta
            )

            var nuevas: Set<Date> = []
            for fecha in diasDeLaSemana {
                guard let rutina = rutinaParaFecha(fecha),
                      let dia = diaParaFecha(fecha, rutina: rutina),
                      !dia.ejercicios.isEmpty else { continue }

                let fechaTexto = HomeViewModel.formatoFecha.string(from: fecha)
                let registrosDelDia = registros.filter { $0.fecha == fechaTexto }

                let completado = dia.ejercicios.allSatisfy { ejercicioDia in
                    registrosDelDia.filter { $0.ejercicioDiaId == ejercicioDia.id }.count >= ejercicioDia.seriesObjetivo
                }
                if completado {
                    nuevas.insert(calendar.startOfDay(for: fecha))
                }
            }
            fechasCompletadas = nuevas
        } catch {
            // Si falla, simplemente no mostramos puntos esa semana —
            // no vale la pena bloquear toda la pantalla por esto.
        }
    }

    private func actualizarDiaSeleccionado() {
        guard let rutina = rutinaParaFecha(fechaSeleccionada) else {
            rutinaMostrada = nil
            diaSeleccionado = nil
            return
        }
        rutinaMostrada = rutina
        diaSeleccionado = diaParaFecha(fechaSeleccionada, rutina: rutina)
    }

    /// Busca, entre TODAS las rutinas del usuario, cuál cubre la fecha
    /// dada por su rango fecha_inicio–fecha_fin. Si más de una la cubre
    /// (tu schema no lo impide), prefiere la marcada `activa`; si ninguna
    /// lo está, la que empezó más recientemente.
    private func rutinaParaFecha(_ fecha: Date) -> RutinaConDias? {
        let calendar = Calendar.current
        let objetivo = calendar.startOfDay(for: fecha)

        let candidatas = rutinas.filter { rutina in
            let inicio = calendar.startOfDay(for: rutina.fechaInicioComoDate)
            guard objetivo >= inicio else { return false }
            if let fin = rutina.fechaFinComoDate, objetivo > calendar.startOfDay(for: fin) { return false }
            return true
        }

        guard !candidatas.isEmpty else { return nil }
        if let activa = candidatas.first(where: { $0.activa }) { return activa }
        return candidatas.max { $0.fechaInicioComoDate < $1.fechaInicioComoDate }
    }

    /// NOTA: el schema no guarda a qué día de la semana corresponde cada
    /// `dia_rutina` — solo un `orden` (1, 2, 3...). Esta función cicla
    /// los días según cuántos días naturales han pasado desde la
    /// `fecha_inicio` de ESA rutina específica hasta la fecha pedida.
    private func diaParaFecha(_ fecha: Date, rutina: RutinaConDias) -> DiaConEjercicios? {
        let calendar = Calendar.current
        let inicio = calendar.startOfDay(for: rutina.fechaInicioComoDate)
        let objetivo = calendar.startOfDay(for: fecha)
        guard !rutina.dias.isEmpty else { return nil }

        let diasOrdenados = rutina.dias.sorted { $0.orden < $1.orden }
        let diasTranscurridos = calendar.dateComponents([.day], from: inicio, to: objetivo).day ?? 0
        let indice = ((diasTranscurridos % diasOrdenados.count) + diasOrdenados.count) % diasOrdenados.count
        return diasOrdenados[indice]
    }

    private func fetchPerfil(_ usuarioId: UUID) async throws -> Perfil {
        try await client
            .from("perfiles")
            .select()
            .eq("id", value: usuarioId)
            .single()
            .execute()
            .value
    }
}
