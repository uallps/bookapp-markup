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
}
