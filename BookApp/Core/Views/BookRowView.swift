import SwiftUI

/// Lomo de un libro en la estantería. No conoce el ViewModel: recibe los flags y la acción.
/// Sí conoce la vista del plugin de fechas (acoplamiento que la sesión 8 quita).
struct BookRowView: View {
    let book: Book
    let dueDate: Date?
    let showDueDates: Bool
    let showPriorities: Bool
    /// En modo edición es `nil`: no se muestra el botón de marcar para poder arrastrar el libro.
    let toggleRead: (() -> Void)?

    var body: some View {
        ZStack {
            Rectangle()
                .fill(book.coverColor.color)

            VStack(spacing: 4) {
                if let toggleRead {
                    Button(action: toggleRead) {
                        Image(systemName: book.isRead ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 6)
                } else {
                    Text("⇄")
                        .bookCaption(color: .white.opacity(0.9))
                        .padding(.top, 6)
                }

                Spacer()

                Text(book.title)
                    .font(.caption)
                    .foregroundColor(.white)
                    .strikethrough(book.isRead)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: 105, height: 48)
                    .rotationEffect(.degrees(-90))

                Spacer()

                if showDueDates, let dueDate {
                    Text(dueDate.formatted(date: .numeric, time: .omitted))
                        .bookCaption(color: .white.opacity(0.85))
                        .lineLimit(1)
                }
#if Prioridades
                if showPriorities, let priority = book.priority {
                    Text(priority.rawValue)
                        .bookCaption(color: .white.opacity(0.9))
                        .lineLimit(1)
                }
#endif
            }
            .padding(.bottom, 4)
        }
        .frame(width: 58, height: 150)
    }
}
