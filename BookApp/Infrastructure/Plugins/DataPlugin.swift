import Foundation

/// Plugin con datos propios ligados a los libros. El registro le avisa cuando se borra
/// un libro, para que borre también sus datos (patrón observador).
protocol DataPlugin: FeaturePlugin {
    /// Antes de borrar el libro: todavía se puede consultar.
    func willDeleteBook(_ book: Book)
    /// Después de borrarlo: ya solo queda su id.
    func didDeleteBook(id: UUID)
}
