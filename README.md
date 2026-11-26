# BookApp 2026

Aplicación de gestión de libros basada en la arquitectura de Líneas de Productos Software (UAL), curso 2026-27.

El mismo código de la carpeta `BookApp/` funciona en los tres sistemas:

| Sistema | Cómo se ejecuta | Interfaz |
|---|---|---|
| macOS | Abrir `BookApp.xcodeproj` en Xcode y pulsar ▶ | SwiftUI de Apple |
| Linux | `swift run BookApp` (necesita `libgtk-4-dev` y `libfontconfig-dev`) | [SwiftOpenUI](https://github.com/uallps/SwiftOpenUI) con GTK 4 |
| Windows | `swift run BookApp` | SwiftOpenUI con Win32 |

En Linux y Windows, `Package.swift` añade un módulo llamado `SwiftUI` (carpeta `Compat/`)
que reexporta SwiftOpenUI, así que `import SwiftUI` funciona sin cambiar el código.

## Productos

| Producto | Xcode (Mac) | Linux y Windows |
|---|---|---|
| Base | scheme `BookApp` | `swift run BookApp` |
| Con prioridades | scheme `BookApp Prioridades` (target con `Prioridades` en *Active Compilation Conditions*) | `swift run --traits Prioridades BookApp` |

## Almacenamiento

Los libros se guardan detrás del protocolo `StorageProvider`, con dos alternativas (solo una activa):

| Alternativa | Dónde | Cómo se elige |
|---|---|---|
| JSON | `books.json` en la carpeta Documentos | Por defecto, en los tres sistemas |
| SwiftData | `BookApp.store` en Application Support | Ajustes → Almacenamiento (solo macOS e iOS) |

SwiftData solo existe en los sistemas de Apple: su código está dentro de `#if canImport(SwiftData)`,
así que en Linux y Windows no se compila y la app guarda siempre en JSON.
