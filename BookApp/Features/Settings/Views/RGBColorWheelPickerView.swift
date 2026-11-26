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

#if os(Windows)
    private let wheelSize: Double = 140
    private let wheelRadius: Double = 60
#else
    private let wheelSize: Double = 220
    private let wheelRadius: Double = 96
#endif

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
        let angle = hue * 2.0 * .pi
        let offsetX = cos(angle) * saturation * wheelRadius
        let offsetY = sin(angle) * saturation * wheelRadius
        let selected = RGBColorWheelPickerView.hsvToRGB(h: hue, s: saturation, v: brightness)
        let hueColors: [Color] = (0...12).map { i in
            let rgb = RGBColorWheelPickerView.hsvToRGB(h: Double(i) / 12.0, s: 1.0, v: brightness)
            return Color(red: rgb.r, green: rgb.g, blue: rgb.b)
        }
        let centerColor = Color(red: brightness, green: brightness, blue: brightness)

        ZStack {
            Circle()
                .fill(AngularGradient(colors: hueColors, center: .center))
                .overlay(
                    Circle().fill(
                        RadialGradient(
                            colors: [centerColor, centerColor.opacity(0.0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: CGFloat(wheelRadius)
                        )
                    )
                )
                .overlay(
                    Circle().stroke(Color.black.opacity(0.22), lineWidth: 1.5)
                )
                .frame(width: CGFloat(wheelRadius * 2), height: CGFloat(wheelRadius * 2))

            Circle()
                .fill(Color(red: selected.r, green: selected.g, blue: selected.b))
                .frame(width: 18, height: 18)
                .overlay(Circle().stroke(Color.white, lineWidth: 3))
                .overlay(Circle().stroke(Color.black.opacity(0.45), lineWidth: 1))
                .offset(x: CGFloat(offsetX), y: CGFloat(offsetY))
        }
        .frame(width: CGFloat(wheelSize), height: CGFloat(wheelSize))
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

#if canImport(SwiftOpenUI)
    private func drawOpenUIWheel(in context: DrawingContext) {
#if canImport(BackendGTK4) || canImport(BackendWin32)
        let cx = wheelSize / 2.0
        let cy = wheelSize / 2.0
        let angleSteps = 120
        let ringSteps = 14
        let dAngle = (2.0 * .pi) / Double(angleSteps)
        let overlap = 0.015

        // Dibuja la rueda mediante sectores polares con arco exterior curvo (sin bordes pixelados)
        for rIndex in (0..<ringSteps).reversed() {
            let rOuter = wheelRadius * Double(rIndex + 1) / Double(ringSteps)
            let rInner = wheelRadius * Double(rIndex) / Double(ringSteps)
            let s = (Double(rIndex) + 0.5) / Double(ringSteps)

            for aIndex in 0..<angleSteps {
                let a0 = Double(aIndex) * dAngle
                let a1 = a0 + dAngle + overlap
                let h = (Double(aIndex) + 0.5) / Double(angleSteps)
                let rgb = RGBColorWheelPickerView.hsvToRGB(h: h, s: s, v: brightness)

                var path = Path()
                if rIndex == 0 {
                    path.move(to: CGPoint(x: cx, y: cy))
                    path.addLine(to: CGPoint(x: cx + cos(a0) * rOuter, y: cy + sin(a0) * rOuter))
                    path.addArc(
                        center: CGPoint(x: cx, y: cy),
                        radius: rOuter,
                        startAngle: a0,
                        endAngle: a1,
                        clockwise: false
                    )
                    path.closeSubpath()
                } else {
                    path.move(to: CGPoint(x: cx + cos(a0) * rInner, y: cy + sin(a0) * rInner))
                    path.addLine(to: CGPoint(x: cx + cos(a0) * rOuter, y: cy + sin(a0) * rOuter))
                    path.addArc(
                        center: CGPoint(x: cx, y: cy),
                        radius: rOuter,
                        startAngle: a0,
                        endAngle: a1,
                        clockwise: false
                    )
                    path.addLine(to: CGPoint(x: cx + cos(a1) * rInner, y: cy + sin(a1) * rInner))
                    path.addArc(
                        center: CGPoint(x: cx, y: cy),
                        radius: rInner,
                        startAngle: a1,
                        endAngle: a0,
                        clockwise: true
                    )
                    path.closeSubpath()
                }

                context.fill(path, with: .color(Color(red: rgb.r, green: rgb.g, blue: rgb.b)))
            }
        }

        // Borde exterior circular limpio
        context.setColor(r: 0, g: 0, b: 0, a: 0.25)
        context.setLineWidth(1.5)
        context.arc(centerX: cx, centerY: cy, radius: wheelRadius)
        context.stroke()

        // Indicador circular del color seleccionado
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
    var onCancel: () -> Void = {}

    @State private var hue: Double
    @State private var saturation: Double
    @State private var brightness: Double

    init(
        title: String,
        initialRGB: (r: Double, g: Double, b: Double),
        onSave: @escaping (Double, Double, Double) -> Void,
        onCancel: @escaping () -> Void = {}
    ) {
        self.title = title
        self.onSave = onSave
        self.onCancel = onCancel
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
#if os(Windows)
        // En Win32, win32PresentSheet crea ventanas de 400x300 pt: compactamos el contenido
        // para que el deslizador de brillo y los botones Cancelar/Guardar no queden cortados.
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Rectangle()
                    .fill(currentColor)
                    .frame(width: 28, height: 28)

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

            VStack(alignment: .leading, spacing: 2) {
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
                    onCancel()
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
        .padding(12)
#else
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
                    onCancel()
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
#endif
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
