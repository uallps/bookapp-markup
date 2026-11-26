import SwiftUI

/// Pantalla de Ajustes: activa o desactiva las características en ejecución.
struct SettingsView: View {
    @Environment(AppConfig.self) private var config

    var body: some View {
        @Bindable var config = config
        Form {
            Section(header: Text("Características")) {
                Toggle("Mostrar fechas de vencimiento", isOn: $config.showDueDates)
#if Prioridades
                Toggle("Mostrar prioridades", isOn: $config.showPriorities)
#endif
            }
#if canImport(SwiftData)
            // Solo en Apple hay dónde elegir; en Linux y Windows los libros van siempre en JSON.
            Section(header: Text("Almacenamiento")) {
                Picker("Guardar los libros en", selection: $config.storageType) {
                    ForEach(StorageType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
            }
#endif
        }
        .navigationTitle("Ajustes")
    }
}
