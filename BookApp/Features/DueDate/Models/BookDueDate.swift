import Foundation

/// La fecha de vencimiento de un libro. Es un dato del plugin, no de `Book`:
/// se une al libro por su id.
struct BookDueDate: Codable {
    let bookID: UUID
    var date: Date
}
