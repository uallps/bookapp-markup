import Foundation
import SwiftUI

/// Formulario modal para crear un libro nuevo.
struct AddBookView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var author: String = ""
    @State private var totalPagesText: String = ""
    @State private var coverColor: BookColor = .blue

    let onCreate: (Book) -> Void
    var onCancel: () -> Void = {}

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
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
    }
}

