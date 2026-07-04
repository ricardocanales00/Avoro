import SwiftUI

/// Paleta definida en la sección 8 del documento de requisitos.
/// Recuerda: Coral es SOLO para indicar progreso/éxito, nunca decorativo.
enum ProgresaColor {
    static let background = Color(hex: "FFFFFF")
    static let surface = Color(hex: "F5F7FA")
    static let primary = Color(hex: "1B2A4A")      // Navy
    static let accent = Color(hex: "F0805A")       // Coral — reservado para progreso
    static let textSecondary = Color(hex: "8B8B85")
    static let border = Color(hex: "E4E4E1")
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

/// Estilo de campo de texto reutilizable para toda la app.
struct ProgresaTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(14)
            .background(ProgresaColor.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(ProgresaColor.border, lineWidth: 1)
            )
            .cornerRadius(10)
    }
}

/// Botón primario (Navy) para acciones principales.
struct ProgresaPrimaryButtonStyle: ButtonStyle {
    var isLoading: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(ProgresaColor.primary.opacity(configuration.isPressed ? 0.85 : 1))
            .cornerRadius(12)
            .opacity(isLoading ? 0.6 : 1)
    }
}
