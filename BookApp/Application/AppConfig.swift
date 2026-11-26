import Foundation
import Observation

/// Feature flags y personalización visual en ejecución: qué características muestra la app,
/// dónde guarda los libros y los colores RGB de las estanterías y el fondo.
/// Cada valor se guarda en UserDefaults al cambiar, así que se conserva al cerrar y volver a abrir.
@Observable
final class AppConfig {
    static let defaultShelfWoodRGB: (r: Double, g: Double, b: Double) = (0.84, 0.85, 0.89)
    static let defaultShelfBgRGB: (r: Double, g: Double, b: Double) = (0.96, 0.96, 0.98)

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

    // Color RGB de las baldas de la estantería (0.0 ... 1.0)
    var shelfWoodRed: Double {
        didSet { store(shelfWoodRed, forKey: "shelfWoodRed") }
    }
    var shelfWoodGreen: Double {
        didSet { store(shelfWoodGreen, forKey: "shelfWoodGreen") }
    }
    var shelfWoodBlue: Double {
        didSet { store(shelfWoodBlue, forKey: "shelfWoodBlue") }
    }

    // Color RGB del fondo de la estantería (0.0 ... 1.0)
    var shelfBgRed: Double {
        didSet { store(shelfBgRed, forKey: "shelfBgRed") }
    }
    var shelfBgGreen: Double {
        didSet { store(shelfBgGreen, forKey: "shelfBgGreen") }
    }
    var shelfBgBlue: Double {
        didSet { store(shelfBgBlue, forKey: "shelfBgBlue") }
    }

    var shelfBgRGB: (r: Double, g: Double, b: Double) {
        (shelfBgRed, shelfBgGreen, shelfBgBlue)
    }

    var shelfWoodRGB: (r: Double, g: Double, b: Double) {
        (shelfWoodRed, shelfWoodGreen, shelfWoodBlue)
    }

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        showDueDates = defaults.object(forKey: "showDueDates") as? Bool ?? true
        showPriorities = defaults.object(forKey: "showPriorities") as? Bool ?? true
        storageType = StorageType(rawValue: defaults.string(forKey: "storageType") ?? "") ?? .json

        shelfWoodRed = defaults.object(forKey: "shelfWoodRed") as? Double ?? Self.defaultShelfWoodRGB.r
        shelfWoodGreen = defaults.object(forKey: "shelfWoodGreen") as? Double ?? Self.defaultShelfWoodRGB.g
        shelfWoodBlue = defaults.object(forKey: "shelfWoodBlue") as? Double ?? Self.defaultShelfWoodRGB.b

        shelfBgRed = defaults.object(forKey: "shelfBgRed") as? Double ?? Self.defaultShelfBgRGB.r
        shelfBgGreen = defaults.object(forKey: "shelfBgGreen") as? Double ?? Self.defaultShelfBgRGB.g
        shelfBgBlue = defaults.object(forKey: "shelfBgBlue") as? Double ?? Self.defaultShelfBgRGB.b
    }

    /// Restaura los colores originales de nogal y lino cálido.
    func resetShelfColors() {
        shelfWoodRed = Self.defaultShelfWoodRGB.r
        shelfWoodGreen = Self.defaultShelfWoodRGB.g
        shelfWoodBlue = Self.defaultShelfWoodRGB.b
        shelfBgRed = Self.defaultShelfBgRGB.r
        shelfBgGreen = Self.defaultShelfBgRGB.g
        shelfBgBlue = Self.defaultShelfBgRGB.b
    }

    private func store(_ value: Any, forKey key: String) {
        defaults.set(value, forKey: key)
        // En Linux y Windows, UserDefaults escribe en disco más tarde: lo forzamos ya.
        defaults.synchronize()
    }
}
