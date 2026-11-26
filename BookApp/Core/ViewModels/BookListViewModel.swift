import Foundation
import Observation

@Observable
final class BookListViewModel {
    static let booksPerShelf = 30
    static let minShelves = 6

    /// Cada cambio en la lista (marcar, añadir, borrar, mover o editar en el detalle) se guarda.
    var books: [Book] = [
        Book(title: "El Quijote", author: "Miguel de Cervantes", totalPages: 1345, coverColor: .orange, priority: .high, shelfRow: 0, shelfCol: 0),
        Book(title: "1984", author: "George Orwell", totalPages: 328, coverColor: .red, priority: .medium, shelfRow: 0, shelfCol: 1),
        Book(title: "Clean Code", author: "Robert C. Martin", totalPages: 464, coverColor: .blue, shelfRow: 0, shelfCol: 2)
    ] {
        didSet { save() }
    }

    @ObservationIgnored private let storageProvider: StorageProvider
    @ObservationIgnored private var loaded = false

    /// Por defecto guarda en JSON; en pruebas se le pasa un MockStorageProvider.
    init(storageProvider: StorageProvider = JSONStorageProvider()) {
        self.storageProvider = storageProvider
        Task { await loadBooks() }
    }

    /// Carga los libros guardados, solo la primera vez que se llama.
    /// Si aún no hay fichero, se quedan los libros de ejemplo.
    func loadBooks() async {
        guard !loaded else { return }
        loaded = true
        do {
            var loadedBooks = try await storageProvider.loadBooks()
            Self.assignMissingPositions(&loadedBooks)
            books = loadedBooks
        } catch {
            print("No se han cargado libros: \(error)")
        }
    }

    func toggleRead(id: UUID) {
        guard let index = books.firstIndex(where: { $0.id == id }) else { return }
        books[index].isRead.toggle()
    }

    func addBook(_ book: Book) {
        var newBook = book
        if newBook.shelfRow == nil || newBook.shelfCol == nil {
            let pos = firstFreePosition(in: books)
            newBook.shelfRow = pos.row
            newBook.shelfCol = pos.col
        }
        books.append(newBook)
    }

    /// Borra un libro. El ViewModel no sabe qué plugins hay: avisa al registro
    /// antes y después, y el registro avisa a cada plugin de datos (observador).
    func removeBook(id: UUID) {
        guard let book = book(id: id) else { return }
        PluginRegistry.shared.notifyBookWillBeDeleted(book)
        books.removeAll { $0.id == id }
        PluginRegistry.shared.notifyBookDidDelete(id: id)
    }

    /// El libro con ese id, si sigue en la lista.
    func book(id: UUID) -> Book? {
        books.first { $0.id == id }
    }

    /// El libro situado en una celda concreta `(row, col)` de la estantería 2D, si hay alguno.
    func book(atRow row: Int, col: Int) -> Book? {
        books.first { $0.shelfRow == row && $0.shelfCol == col }
    }

    /// Sustituye el libro que tiene el mismo id (la usa el detalle al editar).
    func updateBook(_ book: Book) {
        guard let index = books.firstIndex(where: { $0.id == book.id }) else { return }
        books[index] = book
    }

    /// Mueve libremente un libro a cualquier celda `(toRow, toCol)` de la cuadrícula 2D.
    /// Si la celda destino está vacía, el libro ocupa ese hueco dejando libre el anterior;
    /// si había otro libro en esa celda, intercambian sus coordenadas.
    func moveBook(id: UUID, toRow: Int, toCol: Int, maxColumns: Int = booksPerShelf) {
        guard let index = books.firstIndex(where: { $0.id == id }) else { return }
        let allowedCols = max(1, maxColumns)
        let targetRow = max(0, toRow)
        let targetCol = max(0, min(allowedCols - 1, toCol))
        let oldRow = books[index].shelfRow ?? 0
        let oldCol = books[index].shelfCol ?? 0
        guard oldRow != targetRow || oldCol != targetCol else { return }

        var updated = books
        if let otherIndex = updated.firstIndex(where: { $0.id != id && $0.shelfRow == targetRow && $0.shelfCol == targetCol }) {
            updated[otherIndex].shelfRow = oldRow
            updated[otherIndex].shelfCol = oldCol
        }
        updated[index].shelfRow = targetRow
        updated[index].shelfCol = targetCol
        books = updated
    }

    /// Busca el primer hueco libre `(row, col)` recorriendo las baldas de izquierda a derecha.
    private func firstFreePosition(in currentBooks: [Book]) -> (row: Int, col: Int) {
        let occupied = Set(currentBooks.compactMap { b -> String? in
            guard let r = b.shelfRow, let c = b.shelfCol else { return nil }
            return "\(r):\(c)"
        })
        var row = 0
        while true {
            for col in 0..<Self.booksPerShelf {
                if !occupied.contains("\(row):\(col)") {
                    return (row, col)
                }
            }
            row += 1
        }
    }

    /// Garantiza que libros antiguos (sin coordenadas guardadas o duplicadas) tengan celda propia.
    private static func assignMissingPositions(_ list: inout [Book]) {
        var occupied = Set<String>()
        for i in list.indices {
            if let r = list[i].shelfRow, let c = list[i].shelfCol,
               r >= 0, c >= 0,
               !occupied.contains("\(r):\(c)") {
                occupied.insert("\(r):\(c)")
            } else {
                list[i].shelfRow = nil
                list[i].shelfCol = nil
            }
        }
        var row = 0
        var col = 0
        for i in list.indices where list[i].shelfRow == nil {
            while occupied.contains("\(row):\(col)") {
                col += 1
                if col >= booksPerShelf {
                    col = 0
                    row += 1
                }
            }
            list[i].shelfRow = row
            list[i].shelfCol = col
            occupied.insert("\(row):\(col)")
        }
    }

    /// Guarda la lista completa.
    private func save() {
        let books = books
        Task {
            do {
                try await storageProvider.saveBooks(books: books)
            } catch {
                print("No se han guardado los libros: \(error)")
            }
        }
    }
}
