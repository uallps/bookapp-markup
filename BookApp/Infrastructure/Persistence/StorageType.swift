/// Las alternativas de almacenamiento (XOR en el modelo de características):
/// la app usa una y solo una. SwiftData solo aparece donde se puede compilar.
enum StorageType: String, CaseIterable, Identifiable {
    case json = "JSON"
#if canImport(SwiftData)
    case swiftData = "SwiftData"
#endif

    var id: String { rawValue }

    /// El almacenamiento que corresponde a esta opción.
    func makeProvider() -> StorageProvider {
        switch self {
        case .json:
            return JSONStorageProvider()
#if canImport(SwiftData)
        case .swiftData:
            return SwiftDataStorageProvider.shared
#endif
        }
    }
}
