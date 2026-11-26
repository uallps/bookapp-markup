import Foundation

/// Color identificativo del libro (sustituye a una portada obligatoria).
enum BookColor: String, CaseIterable, Codable, Identifiable {
    case blue = "Azul"
    case red = "Rojo"
    case green = "Verde"
    case orange = "Naranja"
    case purple = "Morado"

    var id: String { rawValue }
}

/// Codable: el libro se puede guardar y leer en JSON.
/// La fecha de vencimiento ya no está aquí: es un dato del plugin DueDate.
struct Book: Identifiable, Codable {
    var id = UUID()
    var title: String
    var author: String?
    var totalPages: Int?
    var coverColor: BookColor = .blue
    var isRead: Bool = false
    var priority: Priority?
    /// Posición libre en la cuadrícula 2D de la estantería (balda y columna).
    var shelfRow: Int?
    var shelfCol: Int?

    /// Factor de grosor visual del lomo `[0.54, 0.96]` según el número de páginas.
    var spineThicknessFactor: Double {
        guard let pages = totalPages, pages > 0 else { return 0.72 }
        let minPages = 80.0
        let maxPages = 1000.0
        let normalized = max(0.0, min(1.0, (Double(pages) - minPages) / (maxPages - minPages)))
        return 0.54 + normalized * (0.96 - 0.54)
    }
}
