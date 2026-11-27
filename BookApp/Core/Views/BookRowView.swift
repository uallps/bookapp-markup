import Foundation
import SwiftUI

/// Lomo de un libro en la estantería con diseño moderno minimalista y grosor según sus páginas.
struct BookRowView: View {
    let book: Book
    let cellWidth: Double
    let cellHeight: Double
    let dueDate: Date?
    let showDueDates: Bool
    let showPriorities: Bool
    /// En modo edición es `nil`: no se muestra el botón de marcar para poder arrastrar el libro.
    let toggleRead: (() -> Void)?

    /// Formato compacto `dd/MM/yy` (ej. `13/11/26`) para mostrar la fecha completa en vertical sobre el lomo.
    private static func compactDueDate(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.day, .month, .year], from: date)
        let d = c.day ?? 1
        let m = c.month ?? 1
        let y = (c.year ?? 0) % 100
        return "\(d < 10 ? "0" : "")\(d)/\(m < 10 ? "0" : "")\(m)/\(y < 10 ? "0" : "")\(y)"
    }

    var body: some View {
        let maxCardWidth = max(24.0, cellWidth - 2.0)
        let cardWidth = min(maxCardWidth, max(24.0, (cellWidth * book.spineThicknessFactor).rounded()))
        let innerWidth = max(16.0, cardWidth - 8.0)
        let titleLines = cardWidth < 38.0 ? 1 : 2

#if os(Windows)
        // En Win32 (SwiftOpenUI), usamos Button de Text (FlatButtonState) para respetar
        // .buttonStyle(.plain) y heredar el color del lomo sin caja gris de CustomButton.
        let dueDateLength = 50.0
        let reservedHeight: Double = {
            var total = 44.0
            if showDueDates, dueDate != nil { total += dueDateLength + 4.0 }
#if Prioridades
            if showPriorities, book.priority != nil { total += 18.0 }
#endif
            return total
        }()
        let titleLength = max(36.0, cellHeight - reservedHeight)

        VStack(spacing: 2) {
            if let toggleRead {
                Button(book.isRead ? "✓" : "○", action: toggleRead)
                    .buttonStyle(.plain)
                    .foregroundColor(.white)
            } else {
                Text("⇄")
                    .bookCaption(color: .white)
                    .padding(.top, 4)
            }

            Spacer(minLength: 0)

            Text(book.title)
                .font(.caption)
                .foregroundColor(.bookInk)
                .strikethrough(book.isRead)
                .multilineTextAlignment(.center)
                .lineLimit(titleLines)
                .shelfFrame(width: titleLength, height: innerWidth)
                .rotationEffect(.degrees(-90))

            Spacer(minLength: 0)

            if showDueDates, let dueDate {
                Text(Self.compactDueDate(dueDate))
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .shelfFrame(width: dueDateLength, height: min(innerWidth, 16.0))
                    .rotationEffect(.degrees(-90))
            }
#if Prioridades
            if showPriorities, let priority = book.priority {
                Text(priority.rawValue)
                    .bookCaption(color: .white.opacity(0.92))
                    .lineLimit(1)
            }
#endif
        }
        .padding(.bottom, 4)
        .shelfFrame(width: cardWidth, height: cellHeight)
        .background(book.coverColor.color)
        .shelfFrame(width: cellWidth, height: cellHeight)
#else
        let cardHeight = max(60.0, cellHeight - 4.0)
        let titleLength = max(46.0, cardHeight - 54.0)

        ZStack(alignment: .bottom) {
            ZStack {
                Rectangle()
                    .fill(book.coverColor.color)
                    .shelfFrame(width: cardWidth, height: cardHeight)
                    .overlay(
                        Text(book.title)
                            .font(.caption)
                            .foregroundColor(.bookInk)
                            .strikethrough(book.isRead)
                            .multilineTextAlignment(.center)
                            .lineLimit(titleLines)
                            .shelfFrame(width: titleLength, height: innerWidth)
                            .rotationEffect(.degrees(-90))
                    )

                VStack(spacing: 2) {
                    if let toggleRead {
                        Button(action: toggleRead) {
                            Image(systemName: book.isRead ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(.white.opacity(0.92))
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 7)
                    } else {
                        Text("⇄")
                            .bookCaption(color: .white.opacity(0.9))
                            .padding(.top, 7)
                    }

                    Spacer(minLength: 0)

                    if showDueDates, let dueDate {
                        Text(dueDate.formatted(date: .numeric, time: .omitted))
                            .bookCaption(color: .white.opacity(0.88))
                            .lineLimit(1)
                            .shelfFrame(width: innerWidth, height: 15)
                    }
#if Prioridades
                    if showPriorities, let priority = book.priority {
                        Text(priority.rawValue)
                            .bookCaption(color: .white.opacity(0.92))
                            .lineLimit(1)
                            .shelfFrame(width: innerWidth, height: 15)
                    }
#endif
                }
                .padding(.bottom, 6)
                .shelfFrame(width: cardWidth, height: cardHeight)
            }
            .shelfFrame(width: cardWidth, height: cardHeight)
            .cornerRadius(8)
            .shadow(radius: 2, y: 1)
            .clipped()
        }
        .shelfFrame(width: cellWidth, height: cellHeight)
#endif
    }
}
