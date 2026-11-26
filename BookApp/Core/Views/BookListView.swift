import Foundation
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
    @State private var containerWidth: Double = 650
    /// La configuración la crea la app y llega por el entorno: es la misma que edita Ajustes.
    @Environment(AppConfig.self) private var config
    /// El plugin de fechas también llega por el entorno. La lista le pide la fecha de cada
    /// libro y se la pasa a la fila (el valor) y al detalle (un Binding).
    @Environment(DueDatePlugin.self) private var dueDates

    private let fixedColumns = BookListViewModel.booksPerShelf
    private let fixedRows = BookListViewModel.fixedShelves

    /// Quien crea la lista decide dónde se guardan los libros.
    init(storageProvider: StorageProvider = JSONStorageProvider()) {
        _viewModel = State(wrappedValue: BookListViewModel(storageProvider: storageProvider))
    }

    /// Cuadrícula bidimensional fija (`4 baldas x 10 columnas = 40 celdas`).
    private var shelves: [ShelfRow] {
        (0..<fixedRows).map { row in
            let cells = (0..<fixedColumns).map { col in
                ShelfCell(id: col, book: viewModel.book(atRow: row, col: col))
            }
            return ShelfRow(id: row, cells: cells)
        }
    }

    /// Ancho dinámico de cada celda para rellenar la anchura, manteniendo proporción de lomo de libro (~1 : 2.55).
    private var cellWidth: Double {
        let gaps = Double(fixedColumns - 1)
        return max(32.0, ((containerWidth - gaps - 2.0) / Double(fixedColumns)).rounded(.down))
    }

    /// Alto proporcional al ancho de la celda para que los libros nunca se deformen.
    private var cellHeight: Double {
        (cellWidth * 2.55).rounded()
    }

    /// Grosor estilizado y moderno de cada balda flotante.
    private var woodHeight: Double {
        max(8.0, (cellWidth * 0.16).rounded())
    }

    private var rowTotalWidth: Double {
        cellWidth * Double(fixedColumns) + Double(fixedColumns - 1)
    }

    var body: some View {
        let currentCellWidth = cellWidth
        let currentCellHeight = cellHeight
        let currentWoodHeight = woodHeight
        let currentRowWidth = rowTotalWidth
        NavigationStack {
#if os(Windows)
            // En Win32 evitamos GeometryReader dentro de ZStack porque provoca reconstrucciones
            // en bucle de los HWND (parpadeo) y solapamientos en NavigationSplitView.
            shelfScrollContent(
                cellWidth: currentCellWidth,
                cellHeight: currentCellHeight,
                woodHeight: currentWoodHeight,
                rowWidth: currentRowWidth
            )
            .background(config.shelfBackgroundColor)
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
#else
            ZStack(alignment: .topLeading) {
                // Sensor de anchura sin vistas hijas que dependan de @Environment,
                // compatible tanto con GTK4 (SwiftOpenUI) como con macOS/iOS.
                GeometryReader { geo in
                    let measured = Double(geo.size.width)
                    let _ = updateWidthIfNeeded(measured)
                    Color.clear
                }

                shelfScrollContent(
                    cellWidth: currentCellWidth,
                    cellHeight: currentCellHeight,
                    woodHeight: currentWoodHeight,
                    rowWidth: currentRowWidth
                )
                .frame(minWidth: 0, maxWidth: .infinity)
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .background(config.shelfBackgroundColor)
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
#endif
        }
    }

    private func shelfScrollContent(
        cellWidth currentCellWidth: Double,
        cellHeight currentCellHeight: Double,
        woodHeight currentWoodHeight: Double,
        rowWidth currentRowWidth: Double
    ) -> some View {
        ScrollView {
            ZStack(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(shelves) { shelf in
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(alignment: .bottom, spacing: 1) {
                                ForEach(shelf.cells) { cell in
                                    if let book = cell.book {
                                        bookItem(book: book, cellWidth: currentCellWidth, cellHeight: currentCellHeight)
                                    } else {
                                        emptySlot(cellWidth: currentCellWidth, cellHeight: currentCellHeight)
                                    }
                                }
                            }
                            .shelfFrame(width: currentRowWidth, height: currentCellHeight)

                            shelfPlank(width: currentRowWidth, height: currentWoodHeight)
                        }
                    }
                }

                if isReordering {
                    ShelfDragOverlayView(
                        books: viewModel.books,
                        columns: fixedColumns,
                        rows: fixedRows,
                        slotWidth: currentCellWidth,
                        slotHeight: currentCellHeight,
                        woodHeight: currentWoodHeight,
                        backgroundRGB: config.shelfBgRGB,
                        onMove: { bookID, targetRow, targetCol in
                            viewModel.moveBook(id: bookID, toRow: targetRow, toCol: targetCol)
                        }
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func shelfPlank(width: Double, height: Double) -> some View {
#if os(Windows)
        Rectangle()
            .fill(config.shelfWoodColor)
            .shelfFrame(width: width, height: height)
#else
        Rectangle()
            .fill(config.shelfWoodColor)
            .shelfFrame(width: width, height: height)
            .cornerRadius(5)
            .shadow(radius: 3, y: 2)
#endif
    }

    private func updateWidthIfNeeded(_ measured: Double) {
        guard measured > 100, abs(measured - containerWidth) >= 2.0 else { return }
        DispatchQueue.main.async {
            if abs(measured - containerWidth) >= 2.0 {
                containerWidth = measured
            }
        }
    }

    /// Hueco vacío de la matriz 2D (limpio en lectura, guía sutil en modo edición).
    private func emptySlot(cellWidth: Double, cellHeight: Double) -> some View {
        Rectangle()
            .fill(isReordering ? config.shelfWoodColor.opacity(0.35) : Color.clear)
            .shelfFrame(width: cellWidth, height: cellHeight)
    }

    /// Un libro colocado en la estantería: en modo edición es pasivo (lo arrastra la capa superior);
    /// en modo normal abre su detalle, se puede marcar como leído y tiene menú contextual.
    @ViewBuilder
    private func bookItem(book: Book, cellWidth: Double, cellHeight: Double) -> some View {
        if isReordering {
            BookRowView(
                book: book,
                cellWidth: cellWidth,
                cellHeight: cellHeight,
                dueDate: dueDates.dueDate(for: book.id),
                showDueDates: config.showDueDates,
                showPriorities: config.showPriorities,
                toggleRead: nil
            )
        } else {
            NavigationLink(destination: BookDetailView(book: binding(for: book), dueDate: dueDateBinding(for: book))) {
                BookRowView(
                    book: book,
                    cellWidth: cellWidth,
                    cellHeight: cellHeight,
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
            .shelfFrame(width: cellWidth, height: cellHeight)
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
