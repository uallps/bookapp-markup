import SwiftUI

// El tema de la app: colores y estilos en un solo sitio, añadidos con extensiones.
// Para cambiar el aspecto se toca este fichero, no las vistas.

extension Color {
    /// Color principal de BookApp.
    static let bookAccent = Color(red: 0.19, green: 0.38, blue: 0.58)
    /// Color de las baldas de la estantería.
    static let shelfWood = Color(red: 0.55, green: 0.43, blue: 0.35)
    /// Color de fondo de la estantería.
    static let shelfBackground = Color(red: 0.96, green: 0.95, blue: 0.85)
}

/// Estilo del texto secundario de las filas (fecha, prioridad).
struct CaptionStyle: ViewModifier {
    var color: Color = .secondary

    func body(content: Content) -> some View {
        content
            .font(.caption)
            .foregroundColor(color)
    }
}

extension View {
    /// Aplica el estilo de texto secundario: `Text("…").bookCaption()`,
    /// o con otro color: `.bookCaption(color: .red)`.
    func bookCaption(color: Color = .secondary) -> some View {
        modifier(CaptionStyle(color: color))
    }
}

extension BookColor {
    /// Color de SwiftUI correspondiente al color identificativo del libro.
    var color: Color {
        switch self {
        case .blue: return .bookAccent
        case .red: return .red
        case .green: return .green
        case .orange: return .orange
        case .purple: return .purple
        }
    }

    /// Componentes RGB (0...1) para dibujar el libro en el Canvas durante el arrastre.
    var rgb: (r: Double, g: Double, b: Double) {
        switch self {
        case .blue: return (0.19, 0.38, 0.58)
        case .red: return (0.95, 0.22, 0.20)
        case .green: return (0.13, 0.67, 0.30)
        case .orange: return (0.96, 0.53, 0.12)
        case .purple: return (0.55, 0.24, 0.72)
        }
    }
}

#if Prioridades
extension Priority {
    /// Color de cada prioridad. Solo existe en el producto con prioridades.
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .red
        }
    }
}
#endif
