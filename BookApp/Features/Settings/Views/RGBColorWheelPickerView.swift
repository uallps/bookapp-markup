import Foundation
import SwiftUI
#if !canImport(SwiftOpenUI) && canImport(CoreGraphics)
import CoreGraphics
#endif
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(ucrt)
import ucrt
#endif

/// Rueda circular aislada en su propia vista para que en GTK4/Win32 el redibujo
/// durante el arrastre actualice solo el Canvas sin reconstruir la ventana modal.
private struct ColorWheelCanvasView: View {
    let brightness: Double
    let initialHue: Double
    let initialSaturation: Double
    let onPick: (Double, Double) -> Void

    @State private var hue: Double
    @State private var saturation: Double

    private let wheelSize: Double = 220
    private let wheelRadius: Double = 96

    init(
        brightness: Double,
        initialHue: Double,
        initialSaturation: Double,
        onPick: @escaping (Double, Double) -> Void
    ) {
        self.brightness = brightness
        self.initialHue = initialHue
        self.initialSaturation = initialSaturation
        self.onPick = onPick
        _hue = State(wrappedValue: initialHue)
        _saturation = State(wrappedValue: initialSaturation)
    }

    var body: some View {
#if !canImport(SwiftOpenUI)
        Canvas { context, _ in
            drawAppleWheel(in: &context)
        }
        .shelfFrame(width: wheelSize, height: wheelSize)
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    handlePoint(x: Double(value.location.x), y: Double(value.location.y), commit: false)
                }
                .onEnded { value in
                    handlePoint(x: Double(value.location.x), y: Double(value.location.y), commit: true)
                }
        )
#else
        Canvas(width: Int(wheelSize), height: Int(wheelSize)) { context, _, _ in
            drawOpenUIWheel(in: context)
        }
        .onDrag(
            minimumDistance: 0,
            onChanged: { value in
                handlePoint(x: value.location.x, y: value.location.y, commit: false)
            },
            onEnded: { value in
                handlePoint(x: value.location.x, y: value.location.y, commit: true)
            }
        )
#endif
    }

    private func handlePoint(x: Double, y: Double, commit: Bool) {
        let cx = wheelSize / 2.0
        let cy = wheelSize / 2.0
        let dx = x - cx
        let dy = y - cy
        let dist = hypot(dx, dy)
        let clampedDist = min(dist, wheelRadius)
        var h = atan2(dy, dx) / (2.0 * .pi)
        if h < 0 { h += 1.0 }
        let s = clampedDist / wheelRadius

        hue = h
        saturation = s
        if commit {
            onPick(h, s)
        }
    }

#if !canImport(SwiftOpenUI)
    private func drawAppleWheel(in context: inout GraphicsContext) {
        let cx = wheelSize / 2.0
        let cy = wheelSize / 2.0
        let step = 4.0

        var dy = -wheelRadius
        while dy <= wheelRadius {
            var dx = -wheelRadius
            while dx <= wheelRadius {
                let dist = hypot(dx, dy)
                if dist <= wheelRadius {
                    var h = atan2(dy, dx) / (2.0 * .pi)
                    if h < 0 { h += 1.0 }
                    let s = dist / wheelRadius
                    let rgb = RGBColorWheelPickerView.hsvToRGB(h: h, s: s, v: brightness)
                    let rect = CGRect(x: cx + dx - 2.0, y: cy + dy - 2.0, width: step + 0.8, height: step + 0.8)
                    context.fill(
                        Path(rect),
                        with: GraphicsContext.Shading.color(Color(red: rgb.r, green: rgb.g, blue: rgb.b))
                    )
                }
                dx += step
            }
            dy += step
        }

        let borderRect = CGRect(x: cx - wheelRadius, y: cy - wheelRadius, width: wheelRadius * 2, height: wheelRadius * 2)
        context.stroke(
            Path(ellipseIn: borderRect),
            with: GraphicsContext.Shading.color(Color.black.opacity(0.25)),
            lineWidth: 2
        )

        let angle = hue * 2.0 * .pi
        let sx = cx + cos(angle) * saturation * wheelRadius
        let sy = cy + sin(angle) * saturation * wheelRadius
        let selected = RGBColorWheelPickerView.hsvToRGB(h: hue, s: saturation, v: brightness)
        let handleRect = CGRect(x: sx - 9, y: sy - 9, width: 18, height: 18)

        context.fill(
            Path(ellipseIn: handleRect),
            with: GraphicsContext.Shading.color(Color(red: selected.r, green: selected.g, blue: selected.b))
        )
        context.stroke(
            Path(ellipseIn: handleRect),
            with: GraphicsContext.Shading.color(Color.white),
            lineWidth: 3
        )
        context.stroke(
            Path(ellipseIn: CGRect(x: sx - 10.5, y: sy - 10.5, width: 21, height: 21)),
            with: GraphicsContext.Shading.color(Color.black.opacity(0.45)),
            lineWidth: 1
        )
    }
#else
    private func drawOpenUIWheel(in context: DrawingContext) {
#if canImport(BackendGTK4) || canImport(BackendWin32)
        let cx = wheelSize / 2.0
        let cy = wheelSize / 2.0
        let step = 4.0

        var dy = -wheelRadius
        while dy <= wheelRadius {
            var dx = -wheelRadius
            while dx <= wheelRadius {
                let dist = hypot(dx, dy)
                if dist <= wheelRadius {
                    var h = atan2(dy, dx) / (2.0 * .pi)
                    if h < 0 { h += 1.0 }
                    let s = dist / wheelRadius
                    let rgb = RGBColorWheelPickerView.hsvToRGB(h: h, s: s, v: brightness)
                    context.setColor(r: rgb.r, g: rgb.g, b: rgb.b, a: 1.0)
                    context.rectangle(x: cx + dx - 2.0, y: cy + dy - 2.0, width: step + 0.8, height: step + 0.8)
                    context.fill()
                }
                dx += step
            }
            dy += step
        }

        context.setColor(r: 0, g: 0, b: 0, a: 0.25)
        context.setLineWidth(2)
        context.arc(centerX: cx, centerY: cy, radius: wheelRadius)
        context.stroke()

        let angle = hue * 2.0 * .pi
        let sx = cx + cos(angle) * saturation * wheelRadius
        let sy = cy + sin(angle) * saturation * wheelRadius
        let selected = RGBColorWheelPickerView.hsvToRGB(h: hue, s: saturation, v: brightness)

        context.setColor(r: selected.r, g: selected.g, b: selected.b, a: 1.0)
        context.arc(centerX: sx, centerY: sy, radius: 9)
        context.fill()

        context.setColor(r: 1, g: 1, b: 1, a: 1.0)
        context.setLineWidth(3)
        context.arc(centerX: sx, centerY: sy, radius: 9)
        context.stroke()

        context.setColor(r: 0, g: 0, b: 0, a: 0.45)
        context.setLineWidth(1)
        context.arc(centerX: sx, centerY: sy, radius: 10.5)
        context.stroke()
#endif
    }
#endif
}

/// Modal con rueda circular RGB y deslizador de brillo.
/// Guarda en AppConfig solo al pulsar "Guardar" para evitar reconstruir la ventana durante el arrastre.
struct RGBColorWheelPickerView: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let onSave: (Double, Double, Double) -> Void

    @State private var hue: Double
    @State private var saturation: Double
    @State private var brightness: Double

    init(
        title: String,
        initialRGB: (r: Double, g: Double, b: Double),
        onSave: @escaping (Double, Double, Double) -> Void
    ) {
        self.title = title
        self.onSave = onSave
        let hsv = Self.rgbToHSV(r: initialRGB.r, g: initialRGB.g, b: initialRGB.b)
        _hue = State(wrappedValue: hsv.h)
        _saturation = State(wrappedValue: hsv.s)
        _brightness = State(wrappedValue: max(0.05, hsv.v))
    }

    private var currentRGB: (r: Double, g: Double, b: Double) {
        Self.hsvToRGB(h: hue, s: saturation, v: brightness)
    }

    private var currentColor: Color {
        let rgb = currentRGB
        return Color(red: rgb.r, green: rgb.g, blue: rgb.b)
    }

    var body: some View {
        let rgb = currentRGB
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Rectangle()
                    .fill(currentColor)
                    .frame(width: 36, height: 36)
                    .cornerRadius(18)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text("RGB(\(Int((rgb.r * 255).rounded())), \(Int((rgb.g * 255).rounded())), \(Int((rgb.b * 255).rounded())))")
                        .bookCaption()
                }
                Spacer()
            }

            ColorWheelCanvasView(
                brightness: brightness,
                initialHue: hue,
                initialSaturation: saturation,
                onPick: { newHue, newSat in
                    hue = newHue
                    saturation = newSat
                }
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Brillo")
                        .bookCaption()
                    Spacer()
                    Text("\(Int((brightness * 100).rounded()))%")
                        .bookCaption()
                }
                Slider(value: $brightness, in: 0.05...1.0, step: 0.01)
            }

            HStack {
                Button("Cancelar") {
                    dismiss()
                }
                Spacer()
                Button("Guardar") {
                    let finalRGB = currentRGB
                    onSave(finalRGB.r, finalRGB.g, finalRGB.b)
                    dismiss()
                }
            }
        }
        .padding(20)
        .frame(width: 300, height: 390)
    }

    // MARK: - Conversión RGB <-> HSV

    static func hsvToRGB(h: Double, s: Double, v: Double) -> (r: Double, g: Double, b: Double) {
        let i = Int(h * 6.0)
        let f = h * 6.0 - Double(i)
        let p = v * (1.0 - s)
        let q = v * (1.0 - f * s)
        let t = v * (1.0 - (1.0 - f) * s)
        switch i % 6 {
        case 0: return (v, t, p)
        case 1: return (q, v, p)
        case 2: return (p, v, t)
        case 3: return (p, q, v)
        case 4: return (t, p, v)
        default: return (v, p, q)
        }
    }

    static func rgbToHSV(r: Double, g: Double, b: Double) -> (h: Double, s: Double, v: Double) {
        let maxC = max(r, g, b)
        let minC = min(r, g, b)
        let delta = maxC - minC
        var h: Double = 0
        if delta > 0.0001 {
            if maxC == r {
                h = ((g - b) / delta).truncatingRemainder(dividingBy: 6.0)
            } else if maxC == g {
                h = (b - r) / delta + 2.0
            } else {
                h = (r - g) / delta + 4.0
            }
            h /= 6.0
            if h < 0 { h += 1.0 }
        }
        let s = maxC > 0.0001 ? (delta / maxC) : 0
        return (h, s, maxC)
    }
}
