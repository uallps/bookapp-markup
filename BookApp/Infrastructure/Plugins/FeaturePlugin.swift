/// Lo que tiene todo plugin: una característica que se añade a la app sin que el
/// núcleo (modelo, ViewModel y vistas de la lista) sepa cuál es.
protocol FeaturePlugin: AnyObject {
    /// Nombre del plugin, para los mensajes.
    var name: String { get }
}
