import SwiftUI
#if !canImport(SwiftOpenUI) && canImport(CoreGraphics)
import CoreGraphics
#endif

// El tema de la app: estilo moderno, limpio y minimalista.
// Para cambiar el aspecto se toca este fichero, no las vistas.

extension Color {
    /// Color de acento principal de BookApp (azul cobalto moderno).
    static let bookAccent = Color(red: 0.22, green: 0.45, blue: 0.92)
    /// Colores por defecto de las baldas y el fondo minimalista.
    static let shelfWood = Color(red: 0.84, green: 0.85, blue: 0.89)
    static let shelfBackground = Color(red: 0.96, green: 0.96, blue: 0.98)
    /// Texto blanco limpio sobre los lomos.
    static let bookInk = Color.white
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

    /// Frame con dimensiones en `Double` compatible tanto con SwiftUI de Apple (`CGFloat`) como con SwiftOpenUI (`Double`).
    func shelfFrame(width: Double, height: Double) -> some View {
#if !canImport(SwiftOpenUI)
        self.frame(width: CGFloat(width), height: CGFloat(height))
#else
        self.frame(width: width, height: height)
#endif
    }
}

extension AppConfig {
    /// Color principal de las baldas configurado por el usuario.
    var shelfWoodColor: Color {
        Color(red: shelfWoodRed, green: shelfWoodGreen, blue: shelfWoodBlue)
    }

    /// Color principal del fondo de la estantería configurado por el usuario.
    var shelfBackgroundColor: Color {
        Color(red: shelfBgRed, green: shelfBgGreen, blue: shelfBgBlue)
    }
}

extension BookColor {
    /// Paleta moderna y equilibrada para los libros.
    var color: Color {
        let c = rgb
        return Color(red: c.r, green: c.g, blue: c.b)
    }

    /// Componentes RGB (0...1) compartidos entre el lomo y el Canvas de arrastre.
    var rgb: (r: Double, g: Double, b: Double) {
        switch self {
        case .blue:   return (0.22, 0.45, 0.92) // Cobalto moderno
        case .red:    return (0.90, 0.28, 0.34) // Coral carmesí
        case .green:  return (0.14, 0.68, 0.50) // Esmeralda
        case .orange: return (0.95, 0.55, 0.18) // Ámbar cálido
        case .purple: return (0.52, 0.34, 0.88) // Violeta vivo
        }
    }
}

#if Prioridades
extension Priority {
    /// Color de cada prioridad. Solo existe en el producto con prioridades.
    var color: Color {
        switch self {
        case .low: return Color(red: 0.14, green: 0.68, blue: 0.50)
        case .medium: return Color(red: 0.95, green: 0.66, blue: 0.18)
        case .high: return Color(red: 0.90, green: 0.28, blue: 0.34)
        }
    }
}
#endif
