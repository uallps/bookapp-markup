import SwiftUI

/// La fecha de vencimiento en el detalle: un interruptor para ponerla o quitarla
/// y, si la tiene, el selector de fecha. Edita la fecha a través de un Binding.
struct DueDateDetailView: View {
    @Binding var dueDate: Date?

    var body: some View {
        Toggle("Fecha de vencimiento", isOn: Binding(
            get: { dueDate != nil },
            set: { dueDate = $0 ? Date() : nil }
        ))
        if let date = dueDate {
            DatePicker("Vence", selection: Binding(
                get: { date },
                set: { dueDate = $0 }
            ))
        }
    }
}
