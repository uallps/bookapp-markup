import Foundation
import SwiftUI

private struct ShelfSegment: Identifiable {
    enum Kind {
        case book(Book)
        case gap(count: Int)
    }

    let id: String
    let kind: Kind
}

private struct ShelfRow: Identifiable {
    let id: Int
    let segments: [ShelfSegment]
}

/// Contenido interior de la estantería, aislado dentro del `ScrollView` para que
/// al mover, añadir o marcar libros no se reconstruya el `ScrollView` ni se pierda el scroll en Linux.
private struct ShelfGridContentView: View {
    let viewModel: BookListViewModel
    let isReordering: Bool
    let cellWidth: Double
    let cellHeight: Double
    let woodHeight: Double
    let rowWidth: Double

    @Environment(AppConfig.self) private var config
    @Environment(DueDatePlugin.self) private var dueDates

    private let fixedColumns = BookListViewModel.booksPerShelf
    private let fixedRows = BookListViewModel.fixedShelves

    private var shelves: [ShelfRow] {
        (0..<fixedRows).map { row in
            var segments: [ShelfSegment] = []
            var emptyRun = 0
            var runStart = 0

            for col in 0..<fixedColumns {
                if let book = viewModel.book(atRow: row, col: col) {
                    if emptyRun > 0 {
                        segments.append(ShelfSegment(id: "g-\(row)-\(runStart)", kind: .gap(count: emptyRun)))
                        emptyRun = 0
                    }
                    segments.append(ShelfSegment(id: "b-\(book.id.uuidString)", kind: .book(book)))
                } else {
                    if emptyRun == 0 { runStart = col }
                    emptyRun += 1
                }
            }
            if emptyRun > 0 {
                segments.append(ShelfSegment(id: "g-\(row)-\(runStart)", kind: .gap(count: emptyRun)))
            }
            return ShelfRow(id: row, segments: segments)
        }
    }

    var body: some View {
#if os(Windows)
        if isReordering {
            ShelfDragOverlayView(
                books: viewModel.books,
                columns: fixedColumns,
                rows: fixedRows,
                slotWidth: cellWidth,
                slotHeight: cellHeight,
                woodHeight: woodHeight,
                backgroundRGB: config.shelfBgRGB,
                woodRGB: config.shelfWoodRGB,
                onMove: { bookID, targetRow, targetCol in
                    viewModel.moveBook(id: bookID, toRow: targetRow, toCol: targetCol)
                }
            )
        } else {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(shelves) { shelf in
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .bottom, spacing: 1) {
                            ForEach(shelf.segments) { segment in
                                switch segment.kind {
                                case .book(let book):
                                    bookItem(book: book)
                                case .gap(let count):
                                    let gapWidth = Double(count) * cellWidth + Double(max(0, count - 1))
                                    Spacer(minLength: 0)
                                        .shelfFrame(width: gapWidth, height: cellHeight)
                                }
                            }
                        }
                        .shelfFrame(width: rowWidth, height: cellHeight)

                        shelfPlank
                    }
                }
            }
            .background(config.shelfBackgroundColor)
        }
#else
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(shelves) { shelf in
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .bottom, spacing: 1) {
                            ForEach(shelf.segments) { segment in
                                switch segment.kind {
                                case .book(let book):
                                    bookItem(book: book)
                                case .gap(let count):
                                    let gapWidth = Double(count) * cellWidth + Double(max(0, count - 1))
                                    Spacer(minLength: 0)
                                        .shelfFrame(width: gapWidth, height: cellHeight)
                                }
                            }
                        }
                        .shelfFrame(width: rowWidth, height: cellHeight)

                        shelfPlank
                    }
                }
            }

            if isReordering {
                ShelfDragOverlayView(
                    books: viewModel.books,
                    columns: fixedColumns,
                    rows: fixedRows,
                    slotWidth: cellWidth,
                    slotHeight: cellHeight,
                    woodHeight: woodHeight,
                    backgroundRGB: config.shelfBgRGB,
                    woodRGB: config.shelfWoodRGB,
                    onMove: { bookID, targetRow, targetCol in
                        viewModel.moveBook(id: bookID, toRow: targetRow, toCol: targetCol)
                    }
                )
            }
        }
#endif
    }

    @ViewBuilder
    private var shelfPlank: some View {
#if os(Windows)
        Rectangle()
            .fill(config.shelfWoodColor)
            .shelfFrame(width: rowWidth, height: woodHeight)
#else
        Rectangle()
            .fill(config.shelfWoodColor)
            .shelfFrame(width: rowWidth, height: woodHeight)
            .cornerRadius(5)
            .shadow(radius: 3, y: 2)
#endif
    }

    @ViewBuilder
    private func bookItem(book: Book) -> some View {
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

    private func binding(for book: Book) -> Binding<Book> {
        Binding(
            get: { viewModel.book(id: book.id) ?? book },
            set: { viewModel.updateBook($0) }
        )
    }

    private func dueDateBinding(for book: Book) -> Binding<Date?> {
        let plugin = dueDates
        return Binding(
            get: { plugin.dueDate(for: book.id) },
            set: { plugin.setDueDate($0, for: book.id) }
        )
    }
}

struct BookListView: View {
    @State private var viewModel: BookListViewModel
    @State private var showingAddBook = false
    @State private var isReordering = false
#if os(Windows)
    @State private var containerWidth: Double = 600
#else
    @State private var containerWidth: Double = 650
#endif
    /// La configuración la crea la app y llega por el entorno: es la misma que edita Ajustes.
    @Environment(AppConfig.self) private var config

    private let fixedColumns = BookListViewModel.booksPerShelf

    /// Quien crea la lista decide dónde se guardan los libros.
    init(storageProvider: StorageProvider = JSONStorageProvider()) {
        _viewModel = State(wrappedValue: BookListViewModel(storageProvider: storageProvider))
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
            ScrollView {
                ShelfGridContentView(
                    viewModel: viewModel,
                    isReordering: isReordering,
                    cellWidth: currentCellWidth,
                    cellHeight: currentCellHeight,
                    woodHeight: currentWoodHeight,
                    rowWidth: currentRowWidth
                )
            }
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
                AddBookView(
                    onCreate: { newBook in
                        showingAddBook = false
                        viewModel.addBook(newBook)
                    },
                    onCancel: {
                        showingAddBook = false
                    }
                )
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

                ScrollView {
                    ShelfGridContentView(
                        viewModel: viewModel,
                        isReordering: isReordering,
                        cellWidth: currentCellWidth,
                        cellHeight: currentCellHeight,
                        woodHeight: currentWoodHeight,
                        rowWidth: currentRowWidth
                    )
                }
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
                AddBookView(
                    onCreate: { newBook in
                        showingAddBook = false
                        viewModel.addBook(newBook)
                    },
                    onCancel: {
                        showingAddBook = false
                    }
                )
            }
            .navigationTitle("Libros")
#endif
        }
    }

    private func updateWidthIfNeeded(_ measured: Double) {
        guard measured > 100, abs(measured - containerWidth) >= 2.0 else { return }
        DispatchQueue.main.async {
            if abs(measured - containerWidth) >= 2.0 {
                containerWidth = measured
            }
        }
    }
}
