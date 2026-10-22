import SwiftUI

/// Resolution-independent artwork; all animation is rendered from paths.
struct GrokBotArtwork: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var reactionSeed: UInt64?
    let bot: GrokBot
    var reaction: GrokReaction = .automatic
    var time: Double = 0

    var body: some View {
        Canvas { context, size in
            let silhouette = GrokBotSilhouette(bot: bot).path(in: CGRect(origin: .zero, size: size))
            context.fill(silhouette, with: .color(bot.color))
            context.clip(to: silhouette)
            let track = GrokAutonomousReactions(seed: reactionSeed ?? UInt64(bot.rawValue))
            var pose = GrokEyePose.pose(for: bot, reaction: reaction, time: time, autonomousReactions: track)
            if reduceMotion && reaction == .blink { pose.height = 0.025 }
            for side in [-1.0, 1.0] {
                var eye = context
                eye.translateBy(x: size.width * (pose.x + side * pose.separation / 2), y: size.height * pose.y)
                eye.rotate(by: .radians(side < 0 ? pose.leftTilt : pose.rightTilt))
                let width = size.width * pose.width
                let height = max(size.height * pose.height, size.height * 0.022)
                let rect = CGRect(x: -width / 2, y: -height / 2, width: width, height: height)
                eye.fill(Path(roundedRect: rect, cornerRadius: min(width, height) / 2), with: .color(.white))
            }
        }
        .accessibilityHidden(true)
        .onAppear {
            if reactionSeed == nil { reactionSeed = UInt64.random(in: .min ... .max) }
        }
    }
}

private struct GrokBotSilhouette: Shape {
    let bot: GrokBot

    func path(in rect: CGRect) -> Path {
        let unit: Path
        switch bot {
        case .cloud: unit = Self.cloud
        case .pink: unit = Self.pink
        case .purple: unit = Self.droplet
        case .blue: unit = Self.square
        case .hexagon: unit = Self.hexagon
        case .brown, .red, .amber, .teal:
            return Path(ellipseIn: rect)
        }
        return unit.applying(CGAffineTransform(scaleX: rect.width, y: rect.height)
            .concatenating(CGAffineTransform(translationX: rect.minX, y: rect.minY)))
    }

    private static let cloud = Path { p in
        p.move(to: CGPoint(x: 0.16, y: 0.32))
        p.addCurve(to: CGPoint(x: 0.61, y: 0.10), control1: CGPoint(x: 0.13, y: 0.05), control2: CGPoint(x: 0.43, y: -0.10))
        p.addCurve(to: CGPoint(x: 0.91, y: 0.43), control1: CGPoint(x: 0.80, y: 0.02), control2: CGPoint(x: 0.94, y: 0.20))
        p.addCurve(to: CGPoint(x: 0.80, y: 0.94), control1: CGPoint(x: 1.10, y: 0.65), control2: CGPoint(x: 0.97, y: 0.99))
        p.addCurve(to: CGPoint(x: 0.62, y: 0.94), control1: CGPoint(x: 0.74, y: 0.97), control2: CGPoint(x: 0.68, y: 0.96))
        p.addCurve(to: CGPoint(x: 0.34, y: 0.94), control1: CGPoint(x: 0.54, y: 1.05), control2: CGPoint(x: 0.42, y: 1.04))
        p.addCurve(to: CGPoint(x: 0.04, y: 0.83), control1: CGPoint(x: 0.19, y: 1.01), control2: CGPoint(x: 0.06, y: 0.95))
        p.addCurve(to: CGPoint(x: 0.16, y: 0.32), control1: CGPoint(x: -0.06, y: 0.64), control2: CGPoint(x: 0.02, y: 0.42))
        p.closeSubpath()
    }

    private static let pink = Path { p in
        p.move(to: CGPoint(x: 0.49, y: 0))
        p.addCurve(to: CGPoint(x: 0.97, y: 0.40), control1: CGPoint(x: 0.74, y: -0.03), control2: CGPoint(x: 0.92, y: 0.16))
        p.addCurve(to: CGPoint(x: 0.73, y: 0.98), control1: CGPoint(x: 1.08, y: 0.75), control2: CGPoint(x: 0.95, y: 0.94))
        p.addCurve(to: CGPoint(x: 0.04, y: 0.69), control1: CGPoint(x: 0.43, y: 1.09), control2: CGPoint(x: 0.09, y: 0.94))
        p.addCurve(to: CGPoint(x: 0.49, y: 0), control1: CGPoint(x: -0.12, y: 0.38), control2: CGPoint(x: 0.16, y: 0.03))
        p.closeSubpath()
    }

    private static let droplet = Path { p in
        p.move(to: CGPoint(x: 0.51, y: 0))
        p.addCurve(to: CGPoint(x: 0.98, y: 0.53), control1: CGPoint(x: 0.74, y: -0.01), control2: CGPoint(x: 0.94, y: 0.29))
        p.addCurve(to: CGPoint(x: 0.52, y: 1), control1: CGPoint(x: 1.10, y: 0.83), control2: CGPoint(x: 0.88, y: 1.00))
        p.addCurve(to: CGPoint(x: 0.01, y: 0.60), control1: CGPoint(x: 0.21, y: 1.03), control2: CGPoint(x: -0.05, y: 0.86))
        p.addCurve(to: CGPoint(x: 0.51, y: 0), control1: CGPoint(x: 0.03, y: 0.31), control2: CGPoint(x: 0.27, y: 0.01))
        p.closeSubpath()
    }

    private static let square = Path { p in
        p.move(to: CGPoint(x: 0.23, y: 0.01))
        p.addCurve(to: CGPoint(x: 0.79, y: 0.02), control1: CGPoint(x: 0.39, y: -0.01), control2: CGPoint(x: 0.62, y: 0))
        p.addCurve(to: CGPoint(x: 0.99, y: 0.24), control1: CGPoint(x: 0.94, y: 0.04), control2: CGPoint(x: 1.00, y: 0.09))
        p.addCurve(to: CGPoint(x: 0.98, y: 0.78), control1: CGPoint(x: 1.01, y: 0.41), control2: CGPoint(x: 1.00, y: 0.62))
        p.addCurve(to: CGPoint(x: 0.76, y: 0.99), control1: CGPoint(x: 0.96, y: 0.94), control2: CGPoint(x: 0.91, y: 1.00))
        p.addCurve(to: CGPoint(x: 0.22, y: 0.98), control1: CGPoint(x: 0.60, y: 1.01), control2: CGPoint(x: 0.40, y: 1.00))
        p.addCurve(to: CGPoint(x: 0.01, y: 0.77), control1: CGPoint(x: 0.06, y: 0.96), control2: CGPoint(x: 0.00, y: 0.91))
        p.addCurve(to: CGPoint(x: 0.02, y: 0.23), control1: CGPoint(x: -0.01, y: 0.60), control2: CGPoint(x: 0.00, y: 0.40))
        p.addCurve(to: CGPoint(x: 0.23, y: 0.01), control1: CGPoint(x: 0.04, y: 0.08), control2: CGPoint(x: 0.09, y: 0.03))
        p.closeSubpath()
    }

    private static let hexagon = Path { p in
        p.move(to: CGPoint(x: 0.43, y: 0.02))
        p.addQuadCurve(to: CGPoint(x: 0.57, y: 0.02), control: CGPoint(x: 0.50, y: -0.02))
        p.addLine(to: CGPoint(x: 0.93, y: 0.21))
        p.addQuadCurve(to: CGPoint(x: 1, y: 0.32), control: CGPoint(x: 1, y: 0.25))
        p.addLine(to: CGPoint(x: 1, y: 0.71))
        p.addQuadCurve(to: CGPoint(x: 0.94, y: 0.82), control: CGPoint(x: 1, y: 0.78))
        p.addLine(to: CGPoint(x: 0.57, y: 0.98))
        p.addQuadCurve(to: CGPoint(x: 0.43, y: 0.98), control: CGPoint(x: 0.50, y: 1.02))
        p.addLine(to: CGPoint(x: 0.07, y: 0.79))
        p.addQuadCurve(to: CGPoint(x: 0, y: 0.68), control: CGPoint(x: 0, y: 0.75))
        p.addLine(to: CGPoint(x: 0, y: 0.30))
        p.addQuadCurve(to: CGPoint(x: 0.07, y: 0.19), control: CGPoint(x: 0, y: 0.23))
        p.addLine(to: CGPoint(x: 0.43, y: 0.02))
        p.closeSubpath()
    }
}

/// One clock for each animated surface. Offscreen/background time is excluded
/// so returning to the demo continues the same pose instead of jumping ahead.
struct GrokAnimationTimeline<Content: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var origin = Date()
    @State private var pausedAt: Date?
    @State private var suspension: TimeInterval = 0
    let content: (Double) -> Content

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60, paused: reduceMotion || scenePhase != .active)) { timeline in
            content(reduceMotion ? 0 : max(0, (pausedAt ?? timeline.date).timeIntervalSince(origin) - suspension))
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active, pausedAt == nil {
                pausedAt = Date()
            } else if phase == .active, let pausedAt {
                suspension += Date().timeIntervalSince(pausedAt)
                self.pausedAt = nil
            }
        }
    }
}
