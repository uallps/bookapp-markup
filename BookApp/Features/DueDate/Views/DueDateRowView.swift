import Foundation
import SwiftUI

/// La fecha de vencimiento en la fila de un libro (nada, si no tiene).
/// Recibe el valor, no el plugin: es una vista sencilla.
struct DueDateRowView: View {
    let date: Date?
    var color: Color = .secondary

    var body: some View {
        if let date {
            Text("Vence: \(date.formatted(date: .abbreviated, time: .shortened))")
                .bookCaption(color: color)
        }
    }
}
