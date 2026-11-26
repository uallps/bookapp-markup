import Foundation
import Observation

/// Feature flags en ejecución: qué características muestra la app y dónde guarda los libros.
/// Es configuración de la aplicación, no datos de los libros. Cada valor se guarda en
/// UserDefaults al cambiar, así que se conserva al cerrar y volver a abrir la app.
@Observable
final class AppConfig {
    var showDueDates: Bool {
        didSet { store(showDueDates, forKey: "showDueDates") }
    }
    var showPriorities: Bool {
        didSet { store(showPriorities, forKey: "showPriorities") }
    }
    /// Dónde se guardan los libros. En UserDefaults se guarda su nombre ("JSON", "SwiftData").
    var storageType: StorageType {
        didSet { store(storageType.rawValue, forKey: "storageType") }
    }

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        showDueDates = defaults.object(forKey: "showDueDates") as? Bool ?? true
        showPriorities = defaults.object(forKey: "showPriorities") as? Bool ?? true
        storageType = StorageType(rawValue: defaults.string(forKey: "storageType") ?? "") ?? .json
    }

    private func store(_ value: Any, forKey key: String) {
        defaults.set(value, forKey: key)
        // En Linux y Windows, UserDefaults escribe en disco más tarde: lo forzamos ya.
        defaults.synchronize()
    }
}
