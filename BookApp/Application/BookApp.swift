import Foundation
import SwiftUI

@main
struct BookApp: App {
    /// Una sola configuración para toda la app: la comparten Libros y Ajustes.
    @State private var config = AppConfig()
    @State private var selection: String? = "libros"
    @State private var dueDates: DueDatePlugin

    /// Los plugins se crean y se registran una sola vez, al arrancar la app.
    init() {
        let dueDates = DueDatePlugin()
        PluginRegistry.shared.register(dueDates)
        _dueDates = State(wrappedValue: dueDates)
    }

    var body: some Scene {
        WindowGroup {
#if os(iOS)
            TabView {
                BookListView(storageProvider: config.storageType.makeProvider())
                    // Las pestañas conservan su estado: al cambiar de almacenamiento se rehace la lista.
                    .id(config.storageType)
                    .tabItem { Label("Libros", systemImage: "books.vertical") }
                SettingsView()
                    .tabItem { Label("Ajustes", systemImage: "gearshape") }
            }
            .environment(config)
            .environment(dueDates)
#else
            NavigationSplitView {
#if os(Windows)
                List(selection: $selection) {
                    NavigationLink(selection == "libros" ? "▸ Libros" : "  Libros", value: "libros")
                    NavigationLink(selection == "ajustes" ? "▸ Ajustes" : "  Ajustes", value: "ajustes")
                }
#else
                List(selection: $selection) {
                    NavigationLink(value: "libros") {
                        Label("Libros", systemImage: "books.vertical")
                    }
                    NavigationLink(value: "ajustes") {
                        Label("Ajustes", systemImage: "gearshape")
                    }
                }
#endif
            } detail: {
                switch selection {
                case "libros":
                    // La lista se crea al elegir Libros, con el almacenamiento elegido en Ajustes.
                    BookListView(storageProvider: config.storageType.makeProvider())
                case "ajustes":
                    SettingsView()
                default:
                    Text("Elige una opción")
                }
            }
            .environment(config)
            .environment(dueDates)
#endif
        }
    }
}
