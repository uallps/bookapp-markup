import Foundation
import SwiftUI

#if os(Windows)
/// Almacén mutable sin `@Observable` para que escribir en los `TextField` de Win32
/// no dispare un `WM_SWIFTUI_REBUILD` en cada tecla ni haga perder el foco.
private final class AddBookDraft {
    var title: String = ""
    var author: String = ""
    var totalPagesText: String = ""
    var coverColor: BookColor = .blue
}
#endif

/// Formulario modal para crear un libro nuevo.
struct AddBookView: View {
    @Environment(\.dismiss) private var dismiss

#if os(Windows)
    @State private var draft = AddBookDraft()
    @State private var showTitleError = false
#else
    @State private var title: String = ""
    @State private var author: String = ""
    @State private var totalPagesText: String = ""
    @State private var coverColor: BookColor = .blue
#endif

    let onCreate: (Book) -> Void
    var onCancel: () -> Void = {}

#if !os(Windows)
    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }
#endif

    var body: some View {
#if os(Windows)
        VStack(alignment: .leading, spacing: 10) {
            Text("Nuevo libro")
                .font(.headline)

            TextField("Título", text: Binding(
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

            if showTitleError {
                Text("Introduce un título para guardar.")
                    .bookCaption(color: .red)
            }

            Spacer(minLength: 0)

            HStack {
                Button("Cancelar") {
                    onCancel()
                    dismiss()
                }
                Spacer()
                Button("Guardar") {
                    let trimmedTitle = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmedTitle.isEmpty else {
                        showTitleError = true
                        return
                    }
                    let trimmedAuthor = draft.author.trimmingCharacters(in: .whitespacesAndNewlines)
                    let pages = Int(draft.totalPagesText.trimmingCharacters(in: .whitespacesAndNewlines))
                    let book = Book(
                        title: trimmedTitle,
                        author: trimmedAuthor.isEmpty ? nil : trimmedAuthor,
                        totalPages: pages,
                        coverColor: draft.coverColor
                    )
                    onCreate(book)
                    dismiss()
                }
            }
        }
        .padding(16)
#else
        NavigationStack {
            Form {
                Section(header: Text("Datos del libro")) {
                    TextField("Título", text: $title)
                    TextField("Autor (opcional)", text: $author)
                    TextField("Total de páginas (opcional)", text: $totalPagesText)
                }

                Section(header: Text("Identificación")) {
                    Picker("Color", selection: $coverColor) {
                        ForEach(BookColor.allCases) { color in
                            Text(color.rawValue).tag(color)
                        }
                    }
                }
            }
            .navigationTitle("Nuevo libro")
            .toolbar {
                Button("Cancelar") {
                    onCancel()
                    dismiss()
                }
                Button("Guardar") {
                    let trimmedAuthor = author.trimmingCharacters(in: .whitespacesAndNewlines)
                    let pages = Int(totalPagesText.trimmingCharacters(in: .whitespacesAndNewlines))
                    let book = Book(
                        title: trimmedTitle,
                        author: trimmedAuthor.isEmpty ? nil : trimmedAuthor,
                        totalPages: pages,
                        coverColor: coverColor
                    )
                    onCreate(book)
                    dismiss()
                }
                .disabled(trimmedTitle.isEmpty)
            }
        }
#endif
    }
}

