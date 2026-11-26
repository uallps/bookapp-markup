import Foundation
import SwiftUI

/// Lomo de un libro en la estantería con diseño moderno minimalista.
struct BookRowView: View {
    let book: Book
    let cellWidth: Double
    let cellHeight: Double
    let dueDate: Date?
    let showDueDates: Bool
    let showPriorities: Bool
    /// En modo edición es `nil`: no se muestra el botón de marcar para poder arrastrar el libro.
    let toggleRead: (() -> Void)?

    var body: some View {
#if os(Windows)
        // En Win32 (SwiftOpenUI), cada ZStack/Shadow/Clipped/CornerRadius crea un HWND adicional
        // y ShadowView infla el tamaño de layout; usamos una jerarquía ligera sin sombras ni capas extra.
        let innerWidth = max(20.0, cellWidth - 6.0)
        VStack(spacing: 4) {
            if let toggleRead {
                Button(action: toggleRead) {
                    Image(systemName: book.isRead ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
            } else {
                Text("⇄")
                    .bookCaption(color: .white)
                    .padding(.top, 6)
            }

            Spacer(minLength: 0)

            Text(book.title)
                .font(.caption)
                .foregroundColor(.bookInk)
                .strikethrough(book.isRead)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .shelfFrame(width: innerWidth, height: max(40.0, cellHeight - 60.0))

            Spacer(minLength: 0)

            if showDueDates, let dueDate {
                Text(dueDate.formatted(date: .numeric, time: .omitted))
                    .bookCaption(color: .white.opacity(0.9))
                    .lineLimit(1)
            }
#if Prioridades
            if showPriorities, let priority = book.priority {
                Text(priority.rawValue)
                    .bookCaption(color: .white.opacity(0.92))
                    .lineLimit(1)
            }
#endif
        }
        .padding(.bottom, 6)
        .shelfFrame(width: cellWidth, height: cellHeight)
        .background(book.coverColor.color)
#else
        let cardWidth = max(24.0, cellWidth - 4.0)
        let cardHeight = max(60.0, cellHeight - 4.0)
        let innerWidth = max(18.0, cardWidth - 8.0)
        let titleLength = max(46.0, cardHeight - 54.0)

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
                        .lineLimit(2)
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
        .shelfFrame(width: cellWidth, height: cellHeight)
#endif
    }
}
