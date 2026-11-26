import Foundation
import SwiftUI

/// Detalle de un libro. Recibe un enlace (@Binding) al libro de la lista:
/// lo que se edita aquí cambia el libro del ViewModel, sin copias.
/// La fecha la edita la vista del plugin de fechas, que el detalle conoce directamente.
struct BookDetailView: View {
    @Binding var book: Book
    @Binding var dueDate: Date?

    var body: some View {
        Form {
            TextField("Título del libro", text: $book.title)
            TextField("Autor (opcional)", text: authorBinding)
            TextField("Total de páginas (opcional)", text: totalPagesBinding)
            Picker("Color", selection: $book.coverColor) {
                ForEach(BookColor.allCases) { color in
                    Text(color.rawValue).tag(color)
                }
            }
            Toggle("Leído", isOn: $book.isRead)
            DueDateDetailView(dueDate: $dueDate)
        }
        .navigationTitle(book.title)
    }

    private var authorBinding: Binding<String> {
        Binding(
            get: { book.author ?? "" },
            set: {
                let trimmed = $0.trimmingCharacters(in: .whitespacesAndNewlines)
                book.author = trimmed.isEmpty ? nil : $0
            }
        )
    }

    private var totalPagesBinding: Binding<String> {
        Binding(
            get: { book.totalPages.map(String.init) ?? "" },
            set: {
                let trimmed = $0.trimmingCharacters(in: .whitespacesAndNewlines)
                book.totalPages = trimmed.isEmpty ? nil : Int(trimmed)
            }
        )
    }
}
