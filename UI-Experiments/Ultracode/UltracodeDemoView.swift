import SwiftUI

/// An effort-picker study based on the supplied Ultracode modal recording.
struct UltracodeDemoView: View {
    @State private var isPickerPresented = true
    @State private var selectedEffort: UltracodeEffort = .low

    var body: some View {
        VStack(spacing: 22) {
            UltracodeMascot()
                .frame(width: 62, height: 44)
                .padding(.top, 100)
                .accessibilityHidden(true)
            Text("Back at it, pal!")
                .font(.system(.title, design: .serif))
            Spacer()
            Button {
                isPickerPresented = true
            } label: {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                    Text("Effort")
                    Spacer()
                    Text(selectedEffort.rawValue)
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.up")
                        .font(.caption.weight(.semibold))
                }
                .padding(20)
                .background(.white, in: RoundedRectangle(cornerRadius: 24))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("show-ultracode-picker")
            Text("Open the effort picker to see Ultracode play.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.bottom, 24)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .background(UltracodePalette.paper.ignoresSafeArea())
        .foregroundStyle(.black)
        .navigationTitle("Ultracode")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.light)
        .sheet(isPresented: $isPickerPresented) {
            UltracodeEffortSheet(selection: $selectedEffort)
        }
    }
}

private enum UltracodeEffort: String, CaseIterable, Identifiable {
    case low = "Low", medium = "Medium", high = "High"
    case extra = "Extra", max = "Max", ultracode = "Ultracode"
    var id: Self { self }
}

private enum UltracodePalette {
    static let paper = Color(red: 0.97, green: 0.97, blue: 0.95)
    static let purple = Color(red: 0.15, green: 0.09, blue: 0.26)
    static let orange = Color(red: 0.83, green: 0.39, blue: 0.25)
}

private struct UltracodeEffortSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Binding var selection: UltracodeEffort
    @State private var replay = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                header
                VStack(spacing: 0) {
                    ForEach(UltracodeEffort.allCases) { effort in
                        if effort == .ultracode {
                            UltracodeAnimatedRow(isSelected: selection == effort) {
                                selection = effort
                            }
                            .id(replay)
                        } else {
                            standardRow(effort)
                        }
                    }
                }
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 25))

                Text("Higher effort means more thorough responses, but takes longer and uses your limits faster.")
                    .font(.footnote)
                    .foregroundStyle(Color(white: 0.49))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 18)
                    .padding(.top, -12)
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 30)
        }
        .scrollBounceBehavior(.basedOnSize)
        .presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.height(465)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(36)
        .presentationBackground(UltracodePalette.paper)
        .preferredColorScheme(.light)
    }

    private var header: some View {
        Text("Effort")
            .font(.headline)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .overlay(alignment: .leading) {
                Button("Close", systemImage: "chevron.left") { dismiss() }
                    .labelStyle(.iconOnly)
                    .font(.system(size: 20, weight: .regular))
                    .frame(width: 44, height: 44)
                    .background(UltracodePalette.paper, in: Circle())
                    .overlay(Circle().stroke(.white, lineWidth: 1))
                    .shadow(color: .black.opacity(0.09), radius: 12, y: 8)
                    .accessibilityIdentifier("close-ultracode-picker")
            }
            .overlay(alignment: .trailing) {
                Button("Replay animation", systemImage: "arrow.counterclockwise") {
                    replay += 1
                }
                .labelStyle(.iconOnly)
                .font(.system(size: 16))
                .frame(width: 44, height: 44)
                .accessibilityIdentifier("replay-ultracode")
            }
            .tint(.black)
    }

    private func standardRow(_ effort: UltracodeEffort) -> some View {
        Button {
            selection = effort
        } label: {
            HStack(spacing: 6) {
                Text(effort.rawValue)
                if effort == .high {
                    Text("Default")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(white: 0.9), in: Capsule())
                }
                Spacer()
                if selection == effort {
                    Image(systemName: "checkmark")
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(red: 0.20, green: 0.43, blue: 0.68))
                }
            }
            .font(.body)
            .foregroundStyle(.black)
            .padding(.horizontal, 18)
            .frame(minHeight: 46)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color(white: 0.88))
                    .frame(height: 0.5)
                    .padding(.horizontal, 18)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selection == effort ? .isSelected : [])
    }
}

/// Only this subtree ticks. The picker and its text do not redraw every frame.
private struct UltracodeAnimatedRow: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var start = Date()
    let isSelected: Bool
    let select: () -> Void

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60, paused: reduceMotion || scenePhase != .active)) { timeline in
            let elapsed = reduceMotion ? 3 : max(0, timeline.date.timeIntervalSince(start))
            let reveal = min(1, max(0, (elapsed - 0.45) / 0.28))

            Button(action: select) {
                HStack(spacing: 8) {
                    Text("Ultracode")
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.semibold))
                    }
                    Spacer(minLength: 70)
                }
                .font(.body)
                .foregroundStyle(reveal > 0.5 ? .white : .black)
                .padding(.horizontal, 18)
                .frame(minHeight: 46)
                .background {
                    UltracodeStage(elapsed: elapsed, isStatic: reduceMotion)
                        .opacity(reveal)
                }
                .background(.white)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Ultracode")
            .accessibilityValue(isSelected ? "Selected" : "")
            .accessibilityHint("Use the highest effort level")
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityIdentifier("ultracode-row")
        }
        .onAppear { start = .now }
    }
}

private struct UltracodeStage: View {
    @Environment(\.displayScale) private var displayScale
    let elapsed: TimeInterval
    let isStatic: Bool

    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(
                Gradient(colors: [UltracodePalette.purple, Color(red: 0.24, green: 0.17, blue: 0.36)]),
                startPoint: .zero, endPoint: CGPoint(x: size.width, y: 0)
            ))

            let musicTime = max(0, elapsed - 1.35)
            let center = CGPoint(x: size.width - 39, y: size.height / 2)
            if elapsed > 1.8 {
                drawTiles(context: &context, size: size, center: center, time: elapsed - 1.8)
            }

            var glow = context
            glow.addFilter(.blur(radius: 7))
            glow.fill(Path(ellipseIn: CGRect(x: center.x - 22, y: center.y - 20, width: 44, height: 40)),
                      with: .color(Color(red: 0.43, green: 0.23, blue: 0.85).opacity(0.35)))

            // Whole display pixels keep the smaller details and diagonal frets crisp.
            let unit = (1.3 * displayScale).rounded() / displayScale
            var sprite = context
            sprite.translateBy(x: ((center.x - 18 * unit) * displayScale).rounded() / displayScale,
                               y: ((center.y - 17 * unit) * displayScale).rounded() / displayScale)
            sprite.scaleBy(x: unit, y: unit)
            if elapsed <= 1.05 {
                sprite.translateBy(x: 3, y: 2)
                sprite.scaleBy(x: 1.5, y: 1.5)
            }
            UltracodePixelArt.draw(
                in: &sprite, playing: elapsed > 1.05,
                guitarLift: min(1, max(0, (elapsed - 1.05) / 0.45)),
                time: isStatic ? 0.3 : musicTime
            )
            if elapsed > 1.55 && !isStatic {
                drawNotes(context: &context, center: center, time: musicTime)
            }
        }
        .clipped()
        .accessibilityHidden(true)
    }

    private func drawTiles(context: inout GraphicsContext, size: CGSize, center: CGPoint, time: Double) {
        let pitch = (5.6 * displayScale).rounded() / displayScale
        let gap = 1 / displayScale * 2
        let columns = Int(ceil(size.width / pitch))
        let rows = Int(ceil(size.height / pitch))
        let packetDuration = 0.82
        let latestPacket = time < 0.55 ? 0 : 1 + Int((time - 0.55) / packetDuration)
        let tileColor = Color(red: 0.81, green: 0.75, blue: 0.94)

        // The lattice stays still. Expanding annuli light its cells from right to left.
        // A broad first wash is followed by shorter, overlapping rings with hard fronts.
        for column in 0..<columns {
            for row in 0..<rows {
                let x = Double(column) * pitch
                let y = Double(row) * pitch
                let distance = hypot(x + pitch / 2 - center.x, y + pitch / 2 - center.y)
                var light = 0.0
                for packet in max(0, latestPacket - 2)...latestPacket {
                    let echoes = packet > 0 && packet % 3 != 1 ? 3 : 1
                    for echo in 0..<echoes {
                        let launch = packet == 0 ? 0 : 0.55 + Double(packet - 1) * packetDuration
                        let age = time - launch - Double(echo) * 0.16
                        guard age >= 0 else { continue }
                        let radius = packet == 0 ? 120 + age * 490 : 9 + age * 365
                        let depth = radius - distance
                        let width = packet == 0 ? size.width * 0.95 : 83.0
                        guard depth >= 0, depth < width else { continue }
                        let front = pow(1 - depth / width, 1.3)
                        let strength = echo == 0 ? 0.66 : (echo == 1 ? 0.47 : 0.35)
                        light = max(light, front * strength)
                    }
                }
                guard light > 0.012 else { continue }
                context.fill(
                    Path(CGRect(x: x, y: y, width: pitch - gap, height: pitch - gap)),
                    with: .color(tileColor.opacity(light)), style: FillStyle(antialiased: false)
                )
            }
        }
    }

    private func drawNotes(context: inout GraphicsContext, center: CGPoint, time: Double) {
        let phrase = Int(time / 0.8)
        let phase = (time / 0.8).truncatingRemainder(dividingBy: 1)
        let rise = floor(phase * 5)
        let gold = Color(red: 1, green: 0.86, blue: 0.48)
        let glyphs = [
            ["..x", "..x", ".xx", "xx."],
            ["...x", ".xxx", ".x..", "xx.."],
            ["xx..", ".xxx", "...x", "...."]
        ]
        for index in 0..<3 {
            var note = context
            let overhead = phrase % 3 != 2
            let x = center.x + (overhead ? Double(index * 9 - 9) : Double(17 + index * 2))
            let y = center.y + (overhead ? -15 - rise - Double(index % 2 * 3) : Double(index * 7 - 4) - rise)
            note.translateBy(x: x, y: y)
            note.opacity = min(1, (1 - phase) * 3) * (index == 2 ? 0.75 : 1)
            let glyph = glyphs[(index + phrase) % glyphs.count]
            for (row, line) in glyph.enumerated() {
                for (column, pixel) in line.enumerated() where pixel == "x" {
                    note.fill(Path(CGRect(x: Double(column) * 1.1, y: Double(row) * 1.1, width: 1.1, height: 1.1)),
                              with: .color(gold), style: FillStyle(antialiased: false))
                }
            }
        }
    }
}

/// Layered pixel poses: the picking hand, fretting hand, legs and guitar move separately.
private enum UltracodePixelArt {
    static func draw(in context: inout GraphicsContext, playing: Bool,
                     guitarLift: Double = 1, time: Double = 0) {
        if !playing {
            drawIdle(in: &context)
            return
        }

        let frame = Int(time * 10) % 8
        let bob = [0.0, 0, -1, -1, 0, 0, 1, 0][frame]
        let lean = [0.0, 0, 0, -1, -1, 0, 1, 0][frame]
        var pose = context
        pose.translateBy(x: lean, y: bob)
        drawBody(in: &pose, frame: frame, blinking: time.truncatingRemainder(dividingBy: 2.8) > 2.5)

        var guitar = pose
        // The instrument arrives upright, then tips into its playing position.
        guitar.translateBy(x: 21, y: 24)
        guitar.rotate(by: .degrees(-36 * (1 - guitarLift) + [0.0, 0, -3, -3, 0, 0, 3, 0][frame]))
        guitar.translateBy(x: -21, y: -24)
        drawGuitar(in: &guitar, frame: frame)
        drawHands(in: &pose, frame: frame, guitarLift: guitarLift)
    }

    private static let orange = Color(red: 0.86, green: 0.43, blue: 0.29)
    private static let edge = Color(red: 0.76, green: 0.35, blue: 0.24)
    private static let highlight = Color(red: 0.91, green: 0.48, blue: 0.32)
    private static let ink = Color(red: 0.08, green: 0.09, blue: 0.10)
    private static let violet = Color(red: 0.49, green: 0.48, blue: 0.71)
    private static let lavender = Color(red: 0.63, green: 0.61, blue: 0.82)

    private static func rect(_ context: inout GraphicsContext, _ x: Double, _ y: Double,
                             _ width: Double, _ height: Double, _ color: Color) {
        context.fill(Path(CGRect(x: x, y: y, width: width, height: height)),
                     with: .color(color), style: FillStyle(antialiased: false))
    }

    private static func silhouette(_ context: inout GraphicsContext, _ points: [CGPoint], _ color: Color) {
        var path = Path()
        path.addLines(points)
        path.closeSubpath()
        context.fill(path, with: .color(color), style: FillStyle(antialiased: false))
    }

    private static func drawIdle(in context: inout GraphicsContext) {
        // The greeting uses the original 20 x 18 coordinate space.
        rect(&context, 4, 5, 12, 8, UltracodePalette.orange)
        rect(&context, 1, 8, 3, 3, UltracodePalette.orange)
        rect(&context, 16, 8, 3, 3, UltracodePalette.orange)
        for x in [4.0, 7, 12, 15] { rect(&context, x, 13, 1.5, 3, UltracodePalette.orange) }
        rect(&context, 5.5, 6.5, 1.5, 1.5, ink)
        rect(&context, 13, 6.5, 1.5, 1.5, ink)
    }

    private static func drawBody(in context: inout GraphicsContext, frame: Int, blinking: Bool) {
        silhouette(&context, [
            CGPoint(x: 5, y: 10), CGPoint(x: 23, y: 10), CGPoint(x: 23, y: 24),
            CGPoint(x: 21, y: 24), CGPoint(x: 21, y: 29), CGPoint(x: 19, y: 29),
            CGPoint(x: 19, y: 25), CGPoint(x: 14, y: 25), CGPoint(x: 14, y: 30),
            CGPoint(x: 12, y: 30), CGPoint(x: 12, y: 25), CGPoint(x: 8, y: 25),
            CGPoint(x: 8, y: 30), CGPoint(x: 6, y: 30), CGPoint(x: 6, y: 24),
            CGPoint(x: 4, y: 24), CGPoint(x: 4, y: 14), CGPoint(x: 5, y: 14)
        ], orange)
        rect(&context, 5, 10, 18, 1, highlight)
        rect(&context, 4, 15, 1, 9, edge)
        rect(&context, 5, 24, 1, 5, edge)
        if frame == 2 || frame == 3 {
            rect(&context, 5, 28, 3, 2, orange)
            rect(&context, 12, 29, 2, 1, UltracodePalette.purple)
        }
        // A bent rear arm and a square face remain readable at the row's small scale.
        rect(&context, 7, 20, 1, 2, edge)
        rect(&context, 8, 21, 2, 1, edge)
        rect(&context, 10, 22, 2, 1, edge)
        rect(&context, 7, 13, blinking ? 3 : 2, blinking ? 1 : 2, ink)
        rect(&context, 20, 13, blinking ? 3 : 2, blinking ? 1 : 2, ink)
    }

    private static func drawGuitar(in context: inout GraphicsContext, frame: Int) {
        // A double-cutaway body, dark rim, lavender pickguard and diagonal fretboard.
        silhouette(&context, [
            CGPoint(x: 17, y: 17), CGPoint(x: 19, y: 15), CGPoint(x: 20, y: 15),
            CGPoint(x: 20, y: 19), CGPoint(x: 22, y: 20), CGPoint(x: 24, y: 18),
            CGPoint(x: 26, y: 18), CGPoint(x: 26, y: 21), CGPoint(x: 25, y: 23),
            CGPoint(x: 25, y: 27), CGPoint(x: 23, y: 27), CGPoint(x: 23, y: 29),
            CGPoint(x: 19, y: 30), CGPoint(x: 16, y: 29), CGPoint(x: 14, y: 27),
            CGPoint(x: 14, y: 23), CGPoint(x: 16, y: 21), CGPoint(x: 16, y: 18)
        ], ink)
        silhouette(&context, [
            CGPoint(x: 18, y: 20), CGPoint(x: 19, y: 20), CGPoint(x: 20, y: 22),
            CGPoint(x: 23, y: 21), CGPoint(x: 25, y: 20), CGPoint(x: 24, y: 24),
            CGPoint(x: 23, y: 24), CGPoint(x: 23, y: 27), CGPoint(x: 21, y: 28),
            CGPoint(x: 18, y: 27), CGPoint(x: 16, y: 25), CGPoint(x: 16, y: 23),
            CGPoint(x: 18, y: 23)
        ], violet)
        rect(&context, 19, 22, 3, 2, lavender)
        rect(&context, 20, 24, 3, 2, lavender)
        rect(&context, 18, 25, 1, 1, ink)
        rect(&context, 21, 27, 1, 1, ink)
        rect(&context, 20, 25, 1, 1, Color(white: 0.8))
        for step in 0..<10 {
            let d = Double(step)
            rect(&context, 22 + d, 19 - d, 3, 2, ink)
            if step % 2 == 1 {
                rect(&context, 23 + d, 19 - d, 1, 1, Color(white: 0.72))
            }
        }
        rect(&context, 31, 8, 3, 2, violet)
        rect(&context, 32, 7, 1, 1, ink)
        rect(&context, 34, 9, 2, 1, lavender)
        rect(&context, 31, 10, 1, 1, lavender)
        rect(&context, 32, 8, 1, 1, lavender)
        // A small shoe peeks out from behind the guitar's lower edge.
        rect(&context, 23, 29, frame < 4 ? 2 : 1, 1, orange)
    }

    private static func drawHands(in context: inout GraphicsContext, frame: Int, guitarLift: Double) {
        if guitarLift > 0.6 {
            // Fretting hand wraps around the neck; the other hand crosses the strings.
            rect(&context, 27, 16, 2, 2, orange)
            rect(&context, 28, 15, 2, 2, highlight)
        }
        let downstroke = frame % 4 < 2
        silhouette(&context, downstroke ? [
            CGPoint(x: 12, y: 18), CGPoint(x: 14, y: 18), CGPoint(x: 15, y: 21),
            CGPoint(x: 19, y: 23), CGPoint(x: 19, y: 25), CGPoint(x: 17, y: 25),
            CGPoint(x: 13, y: 22), CGPoint(x: 12, y: 21)
        ] : [
            CGPoint(x: 12, y: 18), CGPoint(x: 14, y: 18), CGPoint(x: 16, y: 20),
            CGPoint(x: 20, y: 21), CGPoint(x: 21, y: 23), CGPoint(x: 18, y: 23),
            CGPoint(x: 14, y: 22), CGPoint(x: 12, y: 20)
        ], orange)
        rect(&context, downstroke ? 18 : 20, downstroke ? 24 : 22, 1, 1, highlight)
    }
}

private struct UltracodeMascot: View {
    var body: some View {
        Canvas { context, size in
            context.scaleBy(x: size.width / 20, y: size.height / 18)
            UltracodePixelArt.draw(in: &context, playing: false)
        }
    }
}

#Preview {
    NavigationStack {
        UltracodeDemoView()
    }
}
