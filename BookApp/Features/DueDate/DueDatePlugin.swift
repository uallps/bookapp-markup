import Foundation
import Observation

/// Plugin de fechas de vencimiento. Guarda la fecha de cada libro en su propio fichero
/// y, como plugin de datos, la borra cuando se borra el libro.
@Observable
final class DueDatePlugin: DataPlugin {
    let name = "Fechas de vencimiento"

    /// Las fechas guardadas. Cada cambio se guarda.
    private(set) var dueDates: [BookDueDate] = [] {
        didSet { save() }
    }

    @ObservationIgnored private let storageProvider: DueDateStorageProvider
    @ObservationIgnored private var loaded = false

    init(storageProvider: DueDateStorageProvider = JSONDueDateStorageProvider()) {
        self.storageProvider = storageProvider
        Task { await loadDueDates() }
    }

    /// Carga las fechas guardadas, solo la primera vez. Si no hay fichero, no hay fechas.
    func loadDueDates() async {
        guard !loaded else { return }
        loaded = true
        do {
            dueDates = try await storageProvider.loadDueDates()
        } catch {
            print("No se han cargado fechas: \(error)")
        }
    }

    /// La fecha de un libro, si tiene.
    func dueDate(for bookID: UUID) -> Date? {
        dueDates.first { $0.bookID == bookID }?.date
    }

    /// Pone o quita (nil) la fecha de un libro.
    func setDueDate(_ date: Date?, for bookID: UUID) {
        var updated = dueDates.filter { $0.bookID != bookID }
        if let date {
            updated.append(BookDueDate(bookID: bookID, date: date))
        }
        dueDates = updated  // un solo cambio: se guarda una vez
    }

    // MARK: - DataPlugin: el registro nos avisa al borrar un libro

    func willDeleteBook(_ book: Book) {
        guard dueDate(for: book.id) != nil else { return }
        setDueDate(nil, for: book.id)
        print("\(name): borrada la fecha de «\(book.title)»")
    }

    func didDeleteBook(id: UUID) {
        print("\(name): el libro \(id) ya no existe")
    }

    private func save() {
        let dueDates = dueDates
        Task {
            do {
                try await storageProvider.saveDueDates(dueDates)
            } catch {
                print("No se han guardado las fechas: \(error)")
            }
        }
    }
}
