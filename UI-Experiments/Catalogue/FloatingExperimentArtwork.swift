import SwiftUI

/// Layered rendition of IconDesign/Iterations/05-floating-experiment.png.
/// All dimensions live in a 360-point artboard; only transforms animate.
enum FloatingExperimentMotion {
    static let duration: Double = 2660

    struct Pose {
        var x: Double = 0
        var y: Double = 0
        var angle: Double = 0
        var lift: Double = 0
        var squash: Double = 1
    }

    static func pose(for piece: ExperimentPiece, at time: Double) -> Pose {
        let t = time - piece.delay
        // Small anticipation, an outward arc, a soft landing, then stillness.
        let travel = flow(t, [(0, 0), (170, -0.045), (640, 1), (850, 1), (1390, 0), (1630, 0)])
        let arc = sin(max(0, min(1, travel)) * .pi)
        let squash = track(t, [Key(0, 1), Key(170, 0.96), Key(550, 1.03),
                               Key(1200, 1.02), Key(1390, 0.94), Key(1630, 1, out: true)])
        return Pose(x: piece.excursion.width * travel,
                    y: piece.excursion.height * travel - 13 * arc,
                    angle: piece.turn * travel,
                    lift: max(0, travel), squash: squash)
    }
}

enum ExperimentPiece: Int, CaseIterable, Identifiable {
    case square, orange, circle, pill
    var id: Int { rawValue }

    var size: CGSize {
        switch self {
        case .square, .orange: CGSize(width: 79, height: 79)
        case .circle: CGSize(width: 81, height: 81)
        case .pill: CGSize(width: 96, height: 46)
        }
    }
    var radius: CGFloat { self == .circle ? 41 : self == .pill ? 23 : 19 }
    var center: CGPoint {
        switch self {
        case .square: CGPoint(x: 65, y: 66)
        case .orange: CGPoint(x: 163, y: 66)
        case .circle: CGPoint(x: 65, y: 163)
        case .pill: CGPoint(x: 164, y: 163)
        }
    }
    var delay: Double {
        switch self {
        case .orange: 140
        case .square: 260
        case .circle: 390
        case .pill: 490
        }
    }
    var excursion: CGSize {
        switch self {
        case .orange: CGSize(width: 36, height: -48)
        case .square: CGSize(width: -32, height: -34)
        case .circle: CGSize(width: -35, height: 30)
        case .pill: CGSize(width: 34, height: 28)
        }
    }
    var turn: Double {
        switch self {
        case .orange: 22
        case .square: -16
        case .circle: -22
        case .pill: 18
        }
    }
}

struct FloatingExperimentArtwork: View {
    let time: Double

    var body: some View {
        GeometryReader { geometry in
            let scale = min(geometry.size.width, geometry.size.height) / 360
            artwork
                .frame(width: 360, height: 360)
                .scaleEffect(scale)
                .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    private var artwork: some View {
        let spread = flow(time, [(0, 0), (700, 1), (1100, 1), (2140, 0)])
        return ZStack {
            card(color: CataloguePalette.ink, edge: Color(red: 0.08, green: 0.20, blue: 0.16))
                .rotationEffect(.degrees(-5 - 3 * spread))
                .offset(x: -23 - 5 * spread, y: 19 + 4 * spread)
            card(color: CataloguePalette.sage, edge: Color(red: 0.68, green: 0.72, blue: 0.60))
                .rotationEffect(.degrees(3 + 2 * spread))
                .offset(x: -10 - 2 * spread, y: 11 + 2 * spread)
            ZStack(alignment: .topLeading) {
                card(color: CataloguePalette.paper, edge: Color(red: 0.78, green: 0.76, blue: 0.68))
                ForEach(ExperimentPiece.allCases) { piece in
                    slot(piece)
                        .position(piece.center)
                }
                ForEach(ExperimentPiece.allCases) { piece in
                    tile(piece)
                        .position(piece.center)
                }
            }
            .frame(width: 228, height: 232)
            .offset(x: 9, y: -9)
        }
        .frame(width: 360, height: 360)
        .rotation3DEffect(.degrees(19), axis: (x: 1, y: -0.25, z: 0), perspective: 0.25)
        .rotationEffect(.degrees(-12))
    }

    private func card(color: Color, edge: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32)
                .fill(edge)
                .offset(y: 7)
            RoundedRectangle(cornerRadius: 32)
                .fill(LinearGradient(colors: [color, color.opacity(0.96)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay {
                    RoundedRectangle(cornerRadius: 32)
                        .strokeBorder(.white.opacity(0.23), lineWidth: 1)
                }
        }
        .frame(width: 228, height: 232)
        .shadow(color: Color(red: 0.22, green: 0.20, blue: 0.12).opacity(0.18), radius: 9, x: 1, y: 12)
    }

    private func slot(_ piece: ExperimentPiece) -> some View {
        RoundedRectangle(cornerRadius: piece.radius)
            .fill(CataloguePalette.ink.shadow(.inner(color: .black.opacity(0.6), radius: 4, x: 2, y: 4)))
            .overlay {
                RoundedRectangle(cornerRadius: piece.radius)
                    .strokeBorder(.white.opacity(0.3), lineWidth: 1)
            }
            .frame(width: piece.size.width, height: piece.size.height)
    }

    private func tile(_ piece: ExperimentPiece) -> some View {
        let pose = FloatingExperimentMotion.pose(for: piece, at: time)
        let orange = piece == .orange
        let color = orange ? CataloguePalette.orange : CataloguePalette.ink
        let restingLift = orange ? 5.0 : 0.0
        let lift = restingLift + 10 * pose.lift
        return ZStack {
            RoundedRectangle(cornerRadius: piece.radius)
                .fill(orange ? Color(red: 0.65, green: 0.25, blue: 0.10) : Color(red: 0.08, green: 0.20, blue: 0.16))
                .offset(y: lift * 0.5)
            RoundedRectangle(cornerRadius: piece.radius)
                .fill(color.gradient)
                .overlay {
                    RoundedRectangle(cornerRadius: piece.radius)
                        .strokeBorder(.white.opacity(orange ? 0.22 : 0.09), lineWidth: 1)
                }
        }
        .frame(width: piece.size.width - 2, height: piece.size.height - 2)
        .shadow(color: .black.opacity(0.10 + 0.10 * pose.lift), radius: 1 + lift * 0.65,
                x: 1 + 3 * pose.lift, y: 1 + lift)
        .scaleEffect(x: 1 / pow(pose.squash, 0.6), y: pose.squash)
        .rotationEffect(.degrees((orange ? -8 : 0) + pose.angle))
        .offset(x: pose.x, y: pose.y - restingLift)
    }
}
