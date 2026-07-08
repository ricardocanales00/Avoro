//
//  RecordatorioEntrenamientoService.swift
//  Avoro
//

import Foundation
import UserNotifications

/// Recordatorio local (no push remoto): si el usuario no registra ninguna
/// serie en `segundos`, iOS dispara sola una notificación aunque la app
/// esté cerrada o el teléfono bloqueado. No depende de Supabase ni de que
/// el servidor esté despierto.
struct RecordatorioEntrenamientoService {
    private static let identificador = "recordatorio-entrenamiento-inactivo"

    /// Pide permiso una sola vez. Solo dispara el prompt si el usuario
    /// nunca ha respondido (`.notDetermined`) — llamarlo varias veces es
    /// seguro y no vuelve a molestar si ya aceptó o rechazó antes.
    static func solicitarPermisoSiHaceFalta() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }
    }

    /// Cancela cualquier recordatorio pendiente y programa uno nuevo a
    /// `segundos` desde ahora. Llamar cada vez que el usuario SÍ registra
    /// datos (resetea el conteo de inactividad), y también al entrar a la
    /// pantalla de ejecución (arranca el conteo desde cero).
    static func reprogramar(despuesDe segundos: TimeInterval = 300) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identificador])

        let contenido = UNMutableNotificationContent()
        contenido.title = "¿Sigues entrenando?"
        contenido.body = "Llevas 5 minutos sin registrar series. Retoma tu rutina para no perder el ritmo."
        contenido.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: segundos, repeats: false)
        let request = UNNotificationRequest(identifier: identificador, content: contenido, trigger: trigger)
        center.add(request)
    }

    /// Se llama cuando el usuario termina todos los ejercicios del día, o
    /// sale de la pantalla de ejecución — ya no tiene sentido recordarle.
    static func cancelar() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identificador])
    }
}
