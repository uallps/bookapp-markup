import SwiftUI

private enum ColorPickerTarget: String, Identifiable {
    case shelfWood
    case shelfBackground

    var id: String { rawValue }
}

/// Pantalla de Ajustes: activa o desactiva características, elige almacenamiento
/// y permite abrir un selector RGB circular al pulsar el color actual de las estanterías o el fondo.
struct SettingsView: View {
    @Environment(AppConfig.self) private var config
    @State private var activeColorPicker: ColorPickerTarget?

    var body: some View {
        @Bindable var config = config
        Form {
            Section(header: Text("Características")) {
                Toggle("Mostrar fechas de vencimiento", isOn: $config.showDueDates)
#if Prioridades
                Toggle("Mostrar prioridades", isOn: $config.showPriorities)
#endif
            }

            Section(header: Text("Apariencia de la estantería")) {
                colorPickerRow(
                    title: "Color de las estanterías",
                    color: config.shelfWoodColor
                ) {
                    activeColorPicker = .shelfWood
                }

                colorPickerRow(
                    title: "Color del fondo",
                    color: config.shelfBackgroundColor
                ) {
                    activeColorPicker = .shelfBackground
                }

                VStack(spacing: 0) {
                    Rectangle()
                        .fill(config.shelfBackgroundColor)
                        .frame(height: 28)
                    Rectangle()
                        .fill(config.shelfWoodColor)
                        .frame(height: 8)
                }
                .cornerRadius(4)

                Button("Restaurar colores por defecto") {
                    config.resetShelfColors()
                }
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
        .sheet(item: $activeColorPicker) { target in
            switch target {
            case .shelfWood:
                RGBColorWheelPickerView(
                    title: "Color de las estanterías",
                    initialRGB: (config.shelfWoodRed, config.shelfWoodGreen, config.shelfWoodBlue),
                    onSave: { r, g, b in
                        config.shelfWoodRed = r
                        config.shelfWoodGreen = g
                        config.shelfWoodBlue = b
                    }
                )
            case .shelfBackground:
                RGBColorWheelPickerView(
                    title: "Color del fondo",
                    initialRGB: (config.shelfBgRed, config.shelfBgGreen, config.shelfBgBlue),
                    onSave: { r, g, b in
                        config.shelfBgRed = r
                        config.shelfBgGreen = g
                        config.shelfBgBlue = b
                    }
                )
            }
        }
        .navigationTitle("Ajustes")
    }

    private func colorPickerRow(title: String, color: Color, action: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
            Spacer()
            Button(action: action) {
#if os(Windows)
                Rectangle()
                    .fill(color)
                    .frame(width: 26, height: 26)
#else
                Circle()
                    .fill(color)
                    .frame(width: 26, height: 26)
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(0.25), lineWidth: 1)
                    )
#endif
            }
            .buttonStyle(.plain)
        }
    }
}
