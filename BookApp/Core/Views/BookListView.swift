import SwiftUI

private struct ShelfCell: Identifiable {
    let id: Int
    let book: Book?
}

private struct ShelfRow: Identifiable {
    let id: Int
    let cells: [ShelfCell]
}

struct BookListView: View {
    @State private var viewModel: BookListViewModel
    @State private var showingAddBook = false
    @State private var isReordering = false
    /// La configuración la crea la app y llega por el entorno: es la misma que edita Ajustes.
    @Environment(AppConfig.self) private var config
    /// El plugin de fechas también llega por el entorno. La lista le pide la fecha de cada
    /// libro y se la pasa a la fila (el valor) y al detalle (un Binding).
    @Environment(DueDatePlugin.self) private var dueDates

    private let minShelves = BookListViewModel.minShelves

    /// Quien crea la lista decide dónde se guardan los libros.
    init(storageProvider: StorageProvider = JSONStorageProvider()) {
        _viewModel = State(wrappedValue: BookListViewModel(storageProvider: storageProvider))
    }

    private var totalColumns: Int {
        let maxStoredCol = viewModel.books.compactMap(\.shelfCol).max() ?? -1
        return max(BookListViewModel.booksPerShelf, maxStoredCol + 2)
    }

    private var totalShelves: Int {
        let maxRow = viewModel.books.compactMap(\.shelfRow).max() ?? -1
        return max(minShelves, maxRow + 2)
    }

    /// Construye la cuadrícula bidimensional de la estantería (`baldas x columnas`),
    /// conservando todos los huecos vacíos entre libros.
    private var shelves: [ShelfRow] {
        let cols = totalColumns
        return (0..<totalShelves).map { row in
            let cells = (0..<cols).map { col in
                ShelfCell(id: col, book: viewModel.book(atRow: row, col: col))
            }
            return ShelfRow(id: row, cells: cells)
        }
    }

    var body: some View {
        let cols = totalColumns
        let rows = totalShelves
        NavigationStack {
            ScrollView([.horizontal, .vertical]) {
                ZStack(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(shelves) { shelf in
                            VStack(alignment: .leading, spacing: 0) {
                                HStack(alignment: .bottom, spacing: 1) {
                                    ForEach(shelf.cells) { cell in
                                        if let book = cell.book {
                                            bookItem(book: book)
                                        } else {
                                            emptySlot
                                        }
                                    }
                                }
                                .frame(height: 150)

                                // Balda de la estantería
                                Rectangle()
                                    .fill(Color.shelfWood)
                                    .frame(height: 14)
                            }
                        }
                    }

                    if isReordering {
                        ShelfDragOverlayView(
                            books: viewModel.books,
                            columns: cols,
                            rows: rows,
                            onMove: { bookID, targetRow, targetCol in
                                viewModel.moveBook(id: bookID, toRow: targetRow, toCol: targetCol, maxColumns: cols)
                            }
                        )
                    }
                }
            }
            .background(Color.shelfBackground)
            .toolbar {
                Button(isReordering ? "Listo" : "Reordenar") {
                    isReordering.toggle()
                }
                Button("Añadir libro") {
                    showingAddBook = true
                }
            }
            .sheet(isPresented: $showingAddBook) {
                AddBookView { newBook in
                    viewModel.addBook(newBook)
                }
            }
            .navigationTitle("Libros")
        }
    }

    /// Hueco vacío de la matriz 2D (ligeramente visible en modo edición para guiar el arrastre).
    private var emptySlot: some View {
        Color.black.opacity(isReordering ? 0.04 : 0.0)
            .frame(width: 58, height: 150)
    }

    /// Un libro colocado en la estantería: en modo edición es pasivo (lo arrastra la capa superior);
    /// en modo normal abre su detalle, se puede marcar como leído y tiene menú contextual.
    @ViewBuilder
    private func bookItem(book: Book) -> some View {
        if isReordering {
            BookRowView(
                book: book,
                dueDate: dueDates.dueDate(for: book.id),
                showDueDates: config.showDueDates,
                showPriorities: config.showPriorities,
                toggleRead: nil
            )
        } else {
            NavigationLink(destination: BookDetailView(book: binding(for: book), dueDate: dueDateBinding(for: book))) {
                BookRowView(
                    book: book,
                    dueDate: dueDates.dueDate(for: book.id),
                    showDueDates: config.showDueDates,
                    showPriorities: config.showPriorities,
                    toggleRead: { viewModel.toggleRead(id: book.id) }
                )
                .contextMenu {
                    Button("Eliminar libro") {
                        viewModel.removeBook(id: book.id)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    /// Un enlace (Binding) para que el detalle edite el libro. No toca los datos:
    /// leer y escribir se traducen a métodos del ViewModel.
    private func binding(for book: Book) -> Binding<Book> {
        Binding(
            get: { viewModel.book(id: book.id) ?? book },
            set: { viewModel.updateBook($0) }
        )
    }

    /// Lo mismo para la fecha: leer y escribir se traducen a métodos del plugin.
    private func dueDateBinding(for book: Book) -> Binding<Date?> {
        // El Binding se usa más tarde (al pulsar): guarda el plugin, no la propiedad del entorno.
        let plugin = dueDates
        return Binding(
            get: { plugin.dueDate(for: book.id) },
            set: { plugin.setDueDate($0, for: book.id) }
        )
    }
}
