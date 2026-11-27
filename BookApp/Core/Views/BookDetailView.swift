import Foundation
import SwiftUI

#if os(Windows)
/// Almacén mutable sin `@Observable` para que editar campos en Win32
/// no dispare un `WM_SWIFTUI_REBUILD` en cada tecla ni destruya los controles.
private final class BookDetailDraft {
    var title: String
    var author: String
    var totalPagesText: String
    var coverColor: BookColor
    var isRead: Bool
    var dueDate: Date?

    init(book: Book, dueDate: Date?) {
        self.title = book.title
        self.author = book.author ?? ""
        self.totalPagesText = book.totalPages.map(String.init) ?? ""
        self.coverColor = book.coverColor
        self.isRead = book.isRead
        self.dueDate = dueDate
    }
}
#endif

/// Detalle de un libro. Recibe un enlace (@Binding) al libro de la lista:
/// lo que se edita aquí cambia el libro del ViewModel, sin copias.
/// La fecha la edita la vista del plugin de fechas, que el detalle conoce directamente.
struct BookDetailView: View {
    @Binding var book: Book
    @Binding var dueDate: Date?
#if os(Windows)
    var onDone: (() -> Void)? = nil
    @State private var draft: BookDetailDraft
    @State private var hasDueDate: Bool
    @State private var showTitleError = false

    init(book: Binding<Book>, dueDate: Binding<Date?>, onDone: (() -> Void)? = nil) {
        _book = book
        _dueDate = dueDate
        self.onDone = onDone
        let currentBook = book.wrappedValue
        let currentDueDate = dueDate.wrappedValue
        _draft = State(wrappedValue: BookDetailDraft(book: currentBook, dueDate: currentDueDate))
        _hasDueDate = State(wrappedValue: currentDueDate != nil)
    }
#endif

    var body: some View {
#if os(Windows)
        VStack(alignment: .leading, spacing: 10) {
            TextField("Título del libro", text: Binding(
                get: { draft.title },
                set: { draft.title = $0 }
            ))
            TextField("Autor (opcional)", text: Binding(
                get: { draft.author },
                set: { draft.author = $0 }
            ))
            TextField("Total de páginas (opcional)", text: Binding(
                get: { draft.totalPagesText },
                set: { draft.totalPagesText = $0 }
            ))
            Picker("Color", selection: Binding(
                get: { draft.coverColor },
                set: { draft.coverColor = $0 }
            )) {
                ForEach(BookColor.allCases) { color in
                    Text(color.rawValue).tag(color)
                }
            }
            Toggle("Leído", isOn: Binding(
                get: { draft.isRead },
                set: { draft.isRead = $0 }
            ))
            Toggle("Fecha de vencimiento", isOn: Binding(
                get: { hasDueDate },
                set: { newValue in
                    hasDueDate = newValue
                    draft.dueDate = newValue ? (draft.dueDate ?? Date()) : nil
                }
            ))
            if hasDueDate {
                DatePicker("Vence", selection: Binding(
                    get: { draft.dueDate ?? Date() },
                    set: { draft.dueDate = $0 }
                ))
            }

            if showTitleError {
                Text("Introduce un título para guardar.")
                    .bookCaption(color: .red)
            }

            Spacer(minLength: 0)

            HStack {
                Spacer()
                Button("Guardar") {
                    let trimmedTitle = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmedTitle.isEmpty else {
                        showTitleError = true
                        return
                    }
                    showTitleError = false
                    let trimmedAuthor = draft.author.trimmingCharacters(in: .whitespacesAndNewlines)
                    let pages = Int(draft.totalPagesText.trimmingCharacters(in: .whitespacesAndNewlines))
                    var updated = book
                    updated.title = trimmedTitle
                    updated.author = trimmedAuthor.isEmpty ? nil : trimmedAuthor
                    updated.totalPages = pages
                    updated.coverColor = draft.coverColor
                    updated.isRead = draft.isRead
                    book = updated
                    dueDate = hasDueDate ? (draft.dueDate ?? Date()) : nil
                    onDone?()
                }
            }
        }
        .padding(16)
#else
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
#endif
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
