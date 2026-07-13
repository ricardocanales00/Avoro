import Foundation
import Combine
import Supabase

@MainActor
final class RutinaEditorViewModel: ObservableObject {
    @Published var nombre = ""
    @Published var descripcion = ""
    @Published var fechaInicio = Date()
    @Published var tieneFechaFin = false
    @Published var fechaFin = Date()
    @Published var activa = true
    /// Cada cuántos días naturales se repite el ciclo (7 = semanal por
    /// default). Ver Models/Rutina.swift para el detalle de diseño.
    @Published var cicloDias = 7

    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = RutinaService()
    private let client = SupabaseService.shared.client
    private let rutinaExistente: Rutina?

    var esEdicion: Bool { rutinaExistente != nil }
    var tituloPantalla: String { esEdicion ? "Editar rutina" : "Nueva rutina" }

    init(rutinaExistente: Rutina?) {
        self.rutinaExistente = rutinaExistente
        if let rutina = rutinaExistente {
            nombre = rutina.nombre
            descripcion = rutina.descripcion ?? ""
            fechaInicio = rutina.fechaInicioComoDate
            activa = rutina.activa
            cicloDias = rutina.cicloDias
            if let finDate = rutina.fechaFinComoDate {
                tieneFechaFin = true
                fechaFin = finDate
            }
        }
    }

    private var validacion: String? {
        if nombre.trimmingCharacters(in: .whitespaces).isEmpty {
            return "Ponle un nombre a tu rutina."
        }
        if tieneFechaFin && fechaFin < fechaInicio {
            return "La fecha final no puede ser antes de la fecha de inicio."
        }
        if cicloDias < 1 {
            return "La duración del ciclo debe ser de al menos 1 día."
        }
        return nil
    }

    /// Guarda (crea o actualiza) y regresa la rutina resultante, para que
    /// la vista pueda navegar al editor de estructura si fue una creación.
    func guardar() async -> Rutina? {
        errorMessage = nil
        if let error = validacion {
            errorMessage = error
            return nil
        }

        guard let usuarioId = client.auth.currentUser?.id else {
            errorMessage = "No se encontró tu sesión."
            return nil
        }

        isLoading = true
        defer { isLoading = false }

        let fechaInicioTexto = Rutina.formatoFecha.string(from: fechaInicio)
        let fechaFinTexto = tieneFechaFin ? Rutina.formatoFecha.string(from: fechaFin) : nil

        do {
            if let existente = rutinaExistente {
                let cambios = RutinaUpdate(
                    nombre: nombre,
                    descripcion: descripcion.isEmpty ? nil : descripcion,
                    fechaInicio: fechaInicioTexto,
                    fechaFin: fechaFinTexto,
                    activa: activa,
                    cicloDias: cicloDias
                )
                try await service.actualizarRutina(id: existente.id, cambios: cambios)
                return Rutina(
                    id: existente.id,
                    nombre: nombre,
                    descripcion: descripcion.isEmpty ? nil : descripcion,
                    fechaInicio: fechaInicioTexto,
                    fechaFin: fechaFinTexto,
                    activa: activa,
                    cicloDias: cicloDias
                )
            } else {
                let nueva = RutinaInsert(
                    usuarioId: usuarioId,
                    nombre: nombre,
                    descripcion: descripcion.isEmpty ? nil : descripcion,
                    fechaInicio: fechaInicioTexto,
                    fechaFin: fechaFinTexto,
                    activa: activa,
                    cicloDias: cicloDias
                )
                return try await service.crearRutina(nueva)
            }
        } catch {
            errorMessage = "No se pudo guardar la rutina. Intenta de nuevo."
            return nil
        }
    }
}
