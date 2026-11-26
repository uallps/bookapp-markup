import Foundation
import SwiftUI
#if !canImport(SwiftOpenUI) && canImport(CoreGraphics)
import CoreGraphics
#endif

private struct ActiveBookDrag {
    let book: Book
    let startRow: Int
    let startCol: Int
    let dx: Double
    let dy: Double
    let targetRow: Int
    let targetCol: Int
}

/// Capa interactiva sobre la estantería en modo edición:
/// dibuja en vivo el libro levantado siguiendo el puntero y el hueco destino con bordes brillantes.
struct ShelfDragOverlayView: View {
    let books: [Book]
    let columns: Int
    let rows: Int
    let slotWidth: Double
    let slotHeight: Double
    let woodHeight: Double
    let backgroundRGB: (r: Double, g: Double, b: Double)
    let woodRGB: (r: Double, g: Double, b: Double)
    let onMove: (UUID, Int, Int) -> Void

    @State private var activeDrag: ActiveBookDrag?

    private var colStride: Double { slotWidth + 1.0 }
    private var rowStride: Double { slotHeight + woodHeight }

    private var totalWidth: Int {
        max(1, Int((slotWidth * Double(columns) + Double(max(0, columns - 1))).rounded()))
    }

    private var totalHeight: Int {
        max(1, Int((Double(rows) * rowStride).rounded()))
    }

    var body: some View {
#if !canImport(SwiftOpenUI)
        Canvas { context, _ in
            drawAppleSlotGuides(in: &context)
            if let drag = activeDrag {
                drawAppleDragPreview(drag, in: &context)
            }
        }
        .frame(width: CGFloat(totalWidth), height: CGFloat(totalHeight))
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 3)
                .onChanged { value in
                    updateDrag(
                        startX: Double(value.startLocation.x),
                        startY: Double(value.startLocation.y),
                        dx: Double(value.translation.width),
                        dy: Double(value.translation.height)
                    )
                }
                .onEnded { value in
                    endDrag(
                        startX: Double(value.startLocation.x),
                        startY: Double(value.startLocation.y),
                        dx: Double(value.translation.width),
                        dy: Double(value.translation.height)
                    )
                }
        )
#else
        Canvas(width: totalWidth, height: totalHeight) { context, _, _ in
            drawOpenUISlotGuides(in: context)
            if let drag = activeDrag {
                drawOpenUIDragPreview(drag, in: context)
            }
        }
        .onDrag(
            minimumDistance: 3,
            onChanged: { value in
                updateDrag(
                    startX: value.startLocation.x,
                    startY: value.startLocation.y,
                    dx: value.translation.width,
                    dy: value.translation.height
                )
            },
            onEnded: { value in
                endDrag(
                    startX: value.startLocation.x,
                    startY: value.startLocation.y,
                    dx: value.translation.width,
                    dy: value.translation.height
                )
            }
        )
#endif
    }

    // MARK: - Lógica de arrastre y cálculo de celda destino

    private func book(atRow row: Int, col: Int) -> Book? {
        books.first { $0.shelfRow == row && $0.shelfCol == col }
    }

    private func computeDrag(startX: Double, startY: Double, dx: Double, dy: Double) -> ActiveBookDrag? {
        let startCol = Int((startX / colStride).rounded(.down))
        let startRow = Int((startY / rowStride).rounded(.down))
        guard startCol >= 0, startCol < columns, startRow >= 0, startRow < rows else { return nil }
        guard let book = book(atRow: startRow, col: startCol) else { return nil }

        let colShift = Int((dx / colStride).rounded())
        let rowShift = Int((dy / rowStride).rounded())
        let targetCol = max(0, min(columns - 1, startCol + colShift))
        let targetRow = max(0, min(rows - 1, startRow + rowShift))

        return ActiveBookDrag(
            book: book,
            startRow: startRow,
            startCol: startCol,
            dx: dx,
            dy: dy,
            targetRow: targetRow,
            targetCol: targetCol
        )
    }

    private func updateDrag(startX: Double, startY: Double, dx: Double, dy: Double) {
        if let current = activeDrag {
            let colShift = Int((dx / colStride).rounded())
            let rowShift = Int((dy / rowStride).rounded())
            let targetCol = max(0, min(columns - 1, current.startCol + colShift))
            let targetRow = max(0, min(rows - 1, current.startRow + rowShift))
            activeDrag = ActiveBookDrag(
                book: current.book,
                startRow: current.startRow,
                startCol: current.startCol,
                dx: dx,
                dy: dy,
                targetRow: targetRow,
                targetCol: targetCol
            )
        } else {
            activeDrag = computeDrag(startX: startX, startY: startY, dx: dx, dy: dy)
        }
    }

    private func endDrag(startX: Double, startY: Double, dx: Double, dy: Double) {
        let finalDrag: ActiveBookDrag?
        if let current = activeDrag {
            let colShift = Int((dx / colStride).rounded())
            let rowShift = Int((dy / rowStride).rounded())
            let targetCol = max(0, min(columns - 1, current.startCol + colShift))
            let targetRow = max(0, min(rows - 1, current.startRow + rowShift))
            finalDrag = ActiveBookDrag(
                book: current.book,
                startRow: current.startRow,
                startCol: current.startCol,
                dx: dx,
                dy: dy,
                targetRow: targetRow,
                targetCol: targetCol
            )
        } else {
            finalDrag = computeDrag(startX: startX, startY: startY, dx: dx, dy: dy)
        }

        activeDrag = nil
        if let finalDrag {
            onMove(finalDrag.book.id, finalDrag.targetRow, finalDrag.targetCol)
        }
    }

    // MARK: - Dibujo en Canvas

    private func bookThicknessGeometry(for book: Book) -> (width: Double, xOffset: Double) {
        let maxBookWidth = max(24.0, slotWidth - 2.0)
        let bookWidth = min(maxBookWidth, max(24.0, (slotWidth * book.spineThicknessFactor).rounded()))
        let xOffset = (slotWidth - bookWidth) / 2.0
        return (bookWidth, xOffset)
    }

#if !canImport(SwiftOpenUI)
    private func drawAppleSlotGuides(in context: inout GraphicsContext) {
        let guideColor = GraphicsContext.Shading.color(Color.black.opacity(0.06))
        for r in 0..<rows {
            for c in 0..<columns where book(atRow: r, col: c) == nil {
                let rect = CGRect(
                    x: Double(c) * colStride + 2,
                    y: Double(r) * rowStride + 4,
                    width: max(4, slotWidth - 4),
                    height: max(4, slotHeight - 4)
                )
                context.fill(Path(rect), with: guideColor)
            }
        }
    }

    private func drawAppleDragPreview(_ drag: ActiveBookDrag, in context: inout GraphicsContext) {
        let geom = bookThicknessGeometry(for: drag.book)
        let originRect = CGRect(
            x: Double(drag.startCol) * colStride + geom.xOffset,
            y: Double(drag.startRow) * rowStride,
            width: geom.width,
            height: slotHeight
        )
        // Hueco de origen atenuado
        context.fill(
            Path(originRect),
            with: GraphicsContext.Shading.color(
                Color(red: backgroundRGB.r, green: backgroundRGB.g, blue: backgroundRGB.b).opacity(0.82)
            )
        )

        // Previsualización iluminada con bordes brillantes en la celda destino
        let tx = Double(drag.targetCol) * colStride + geom.xOffset
        let ty = Double(drag.targetRow) * rowStride
        let targetRect = CGRect(x: tx, y: ty, width: geom.width, height: slotHeight)
        let rgb = drag.book.coverColor.rgb

        context.fill(
            Path(targetRect),
            with: GraphicsContext.Shading.color(Color(red: rgb.r, green: rgb.g, blue: rgb.b).opacity(0.28))
        )
        context.stroke(
            Path(CGRect(x: tx - 2, y: ty - 2, width: geom.width + 4, height: slotHeight + 4)),
            with: GraphicsContext.Shading.color(Color(red: 1.0, green: 0.90, blue: 0.35).opacity(0.45)),
            lineWidth: 6
        )
        context.stroke(
            Path(targetRect),
            with: GraphicsContext.Shading.color(Color(red: 1.0, green: 0.96, blue: 0.62).opacity(0.95)),
            lineWidth: 3
        )
        context.stroke(
            Path(CGRect(x: tx + 1.5, y: ty + 1.5, width: max(2, geom.width - 3), height: slotHeight - 3)),
            with: GraphicsContext.Shading.color(Color.white.opacity(0.95)),
            lineWidth: 1.5
        )

        // Libro flotando siguiendo el arrastre
        let fx = Double(drag.startCol) * colStride + geom.xOffset + drag.dx
        let fy = Double(drag.startRow) * rowStride + drag.dy - 4
        let shadowRect = CGRect(x: fx + 6, y: fy + 8, width: geom.width, height: slotHeight)
        let floatingRect = CGRect(x: fx, y: fy, width: geom.width, height: slotHeight)

        context.fill(Path(shadowRect), with: GraphicsContext.Shading.color(Color.black.opacity(0.28)))
        context.fill(
            Path(floatingRect),
            with: GraphicsContext.Shading.color(Color(red: rgb.r, green: rgb.g, blue: rgb.b).opacity(0.94))
        )
        context.fill(
            Path(CGRect(x: fx, y: fy, width: 6, height: slotHeight)),
            with: GraphicsContext.Shading.color(Color.white.opacity(0.18))
        )
        context.stroke(Path(floatingRect), with: GraphicsContext.Shading.color(Color.white.opacity(0.9)), lineWidth: 2)
    }
#else
    private func drawOpenUISlotGuides(in context: DrawingContext) {
#if canImport(BackendGTK4) || canImport(BackendWin32)
#if os(Windows)
        // En Win32 Canvas limpia el fondo de forma opaca, así que dibujamos también
        // el fondo, las baldas y los libros en reposo para que la estantería sea visible.
        context.setColor(r: backgroundRGB.r, g: backgroundRGB.g, b: backgroundRGB.b, a: 1.0)
        context.rectangle(x: 0, y: 0, width: Double(totalWidth), height: Double(totalHeight))
        context.fill()

        context.setColor(r: woodRGB.r, g: woodRGB.g, b: woodRGB.b, a: 1.0)
        for r in 0..<rows {
            context.rectangle(
                x: 0,
                y: Double(r) * rowStride + slotHeight,
                width: Double(totalWidth),
                height: woodHeight
            )
            context.fill()
        }
#endif
        context.setColor(r: 0, g: 0, b: 0, a: 0.06)
        for r in 0..<rows {
            for c in 0..<columns where book(atRow: r, col: c) == nil {
                context.rectangle(
                    x: Double(c) * colStride + 2,
                    y: Double(r) * rowStride + 4,
                    width: max(4, slotWidth - 4),
                    height: max(4, slotHeight - 4)
                )
                context.fill()
            }
        }
#if os(Windows)
        for b in books {
            if activeDrag?.book.id == b.id { continue }
            guard let r = b.shelfRow, let c = b.shelfCol else { continue }
            let geom = bookThicknessGeometry(for: b)
            let bx = Double(c) * colStride + geom.xOffset
            let by = Double(r) * rowStride
            let rgb = b.coverColor.rgb

            context.setColor(r: rgb.r, g: rgb.g, b: rgb.b, a: 1.0)
            context.rectangle(x: bx, y: by, width: geom.width, height: slotHeight)
            context.fill()

            context.setColor(r: 1.0, g: 1.0, b: 1.0, a: 0.25)
            context.setLineWidth(1)
            context.rectangle(x: bx, y: by, width: geom.width, height: slotHeight)
            context.stroke()

            // Indicador de libro leído o en movimiento
            context.setColor(r: 1.0, g: 1.0, b: 1.0, a: b.isRead ? 0.95 : 0.45)
            context.arc(centerX: bx + geom.width / 2.0, centerY: by + 12.0, radius: 4.0)
            if b.isRead {
                context.fill()
            } else {
                context.setLineWidth(1.5)
                context.stroke()
            }
        }
#endif
#endif
    }

    private func drawOpenUIDragPreview(_ drag: ActiveBookDrag, in context: DrawingContext) {
#if canImport(BackendGTK4) || canImport(BackendWin32)
        let geom = bookThicknessGeometry(for: drag.book)
        let ox = Double(drag.startCol) * colStride + geom.xOffset
        let oy = Double(drag.startRow) * rowStride

        // 1. Hueco de origen atenuado (el libro se ha levantado de aquí)
        context.setColor(r: backgroundRGB.r, g: backgroundRGB.g, b: backgroundRGB.b, a: 0.82)
        context.rectangle(x: ox, y: oy, width: geom.width, height: slotHeight)
        context.fill()

        // 2. Previsualización con bordes brillantes en la posición destino
        let tx = Double(drag.targetCol) * colStride + geom.xOffset
        let ty = Double(drag.targetRow) * rowStride
        let rgb = drag.book.coverColor.rgb

        // Relleno translúcido del color del libro en la celda destino
        context.setColor(r: rgb.r, g: rgb.g, b: rgb.b, a: 0.28)
        context.rectangle(x: tx, y: ty, width: geom.width, height: slotHeight)
        context.fill()

        // Halo exterior brillante
        context.setColor(r: 1.0, g: 0.90, b: 0.35, a: 0.45)
        context.setLineWidth(6)
        context.rectangle(x: tx - 2, y: ty - 2, width: geom.width + 4, height: slotHeight + 4)
        context.stroke()

        // Borde dorado luminoso
        context.setColor(r: 1.0, g: 0.96, b: 0.62, a: 0.95)
        context.setLineWidth(3)
        context.rectangle(x: tx, y: ty, width: geom.width, height: slotHeight)
        context.stroke()

        // Filo interior blanco brillante
        context.setColor(r: 1.0, g: 1.0, b: 1.0, a: 0.95)
        context.setLineWidth(1.5)
        context.rectangle(x: tx + 1.5, y: ty + 1.5, width: max(2, geom.width - 3), height: slotHeight - 3)
        context.stroke()

        // 3. Libro flotando con sombra siguiendo el puntero
        let fx = ox + drag.dx
        let fy = oy + drag.dy - 4

        context.setColor(r: 0.0, g: 0.0, b: 0.0, a: 0.28)
        context.rectangle(x: fx + 6, y: fy + 8, width: geom.width, height: slotHeight)
        context.fill()

        context.setColor(r: rgb.r, g: rgb.g, b: rgb.b, a: 0.94)
        context.rectangle(x: fx, y: fy, width: geom.width, height: slotHeight)
        context.fill()

        // Brillo lateral del lomo levantado
        context.setColor(r: 1.0, g: 1.0, b: 1.0, a: 0.18)
        context.rectangle(x: fx, y: fy, width: 6, height: slotHeight)
        context.fill()

        // Borde brillante alrededor del libro arrastrado
        context.setColor(r: 1.0, g: 1.0, b: 1.0, a: 0.9)
        context.setLineWidth(2)
        context.rectangle(x: fx, y: fy, width: geom.width, height: slotHeight)
        context.stroke()
#endif
    }
#endif
}
