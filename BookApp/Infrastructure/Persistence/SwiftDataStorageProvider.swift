// SwiftData solo existe en los sistemas de Apple. En Linux y Windows este fichero
// queda vacío al compilar y la app guarda siempre en JSON.
#if canImport(SwiftData)
import Foundation
import SwiftData

/// Cómo guarda SwiftData un libro. `Book` sigue siendo un struct que usan las vistas
/// y el ViewModel; esta clase solo la conoce el almacenamiento.
@Model
final class BookEntity {
    @Attribute(.unique) var id: UUID
    var title: String
    var author: String?
    var totalPages: Int?
    var coverColor: BookColor
    var isRead: Bool
    var priority: Priority?
    var shelfRow: Int?
    var shelfCol: Int?
    /// SwiftData no guarda el orden de la lista: lo guardamos nosotros.
    var position: Int

    init(book: Book, position: Int) {
        id = book.id
        title = book.title
        author = book.author
        totalPages = book.totalPages
        coverColor = book.coverColor
        isRead = book.isRead
        priority = book.priority
        shelfRow = book.shelfRow
        shelfCol = book.shelfCol
        self.position = position
    }

    /// Copia en la entidad lo que se ha cambiado en el libro.
    func update(from book: Book, position: Int) {
        title = book.title
        author = book.author
        totalPages = book.totalPages
        coverColor = book.coverColor
        isRead = book.isRead
        priority = book.priority
        shelfRow = book.shelfRow
        shelfCol = book.shelfCol
        self.position = position
    }

    /// El libro que usan las vistas.
    var book: Book {
        Book(
            id: id,
            title: title,
            author: author,
            totalPages: totalPages,
            coverColor: coverColor,
            isRead: isRead,
            priority: priority,
            shelfRow: shelfRow,
            shelfCol: shelfCol
        )
    }
}

/// Guarda los libros en una base de datos de SwiftData (un fichero BookApp.store).
final class SwiftDataStorageProvider: StorageProvider {
    /// Un solo almacén para toda la app, aunque la lista se cree varias veces.
    static let shared = SwiftDataStorageProvider()

    private let container: ModelContainer

    private init() {
        do {
            container = try ModelContainer(
                for: BookEntity.self,
                configurations: ModelConfiguration("BookApp"))
        } catch {
            fatalError("No se ha podido abrir el almacén de SwiftData: \(error)")
        }
    }

    private var context: ModelContext { container.mainContext }

    func loadBooks() async throws -> [Book] {
        let byPosition = FetchDescriptor<BookEntity>(sortBy: [SortDescriptor(\.position)])
        return try context.fetch(byPosition).map(\.book)
    }

    func saveBooks(books: [Book]) async throws {
        // Las entidades guardadas, por id, para saber cuáles cambian y cuáles sobran.
        var stored: [UUID: BookEntity] = [:]
        for entity in try context.fetch(FetchDescriptor<BookEntity>()) {
            stored[entity.id] = entity
        }

        for (position, book) in books.enumerated() {
            if let entity = stored.removeValue(forKey: book.id) {
                entity.update(from: book, position: position)
            } else {
                context.insert(BookEntity(book: book, position: position))
            }
        }
        // Los que quedan ya no están en la lista: se han borrado.
        for entity in stored.values {
            context.delete(entity)
        }
        try context.save()
    }
}
#endif
