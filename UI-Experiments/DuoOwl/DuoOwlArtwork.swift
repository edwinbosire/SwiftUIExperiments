import SwiftUI

/// Resolution-independent owl artwork drawn as native SwiftUI shapes so each
/// moving part can rotate around its own pivot. The outer rounded square is
/// the "layout" — only the owl inside it moves.
struct DuoOwlArtwork: View {
    let pose: DuoPose
    let time: Double

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let frame = CGRect(x: (geo.size.width - side) / 2,
                               y: (geo.size.height - side) / 2,
                               width: side, height: side)
            ZStack {
                // Container (the "layout" — never moves).
                RoundedRectangle(cornerRadius: side * 0.18, style: .continuous)
                    .fill(DuoPalette.containerGreen)

                // Everything inside the owl moves together: breath lift,
                // head tilt and the small vertical squash from reactions.
                DuoOwlInner(pose: pose, time: time, side: side)
                    .frame(width: side, height: side)
                    .scaleEffect(x: 1 / pow(max(pose.squashY, 0.6), 0.6),
                                 y: pose.squashY,
                                 anchor: .bottom)
                    .offset(y: side * pose.lift)
                    .rotationEffect(.degrees(pose.tilt), anchor: UnitPoint(x: 0.5, y: 0.92))
                    .clipShape(RoundedRectangle(cornerRadius: side * 0.18, style: .continuous))
            }
            .frame(width: side, height: side)
            .position(x: frame.midX, y: frame.midY)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

private struct DuoOwlInner: View {
    let pose: DuoPose
    let time: Double
    let side: Double

    var body: some View {
        ZStack {
            DuoHeadShape()
                .fill(DuoPalette.faceGreen)

            // Left and right eye assemblies.
            DuoEyeAssembly(center: .init(x: 0.33, y: 0.48),
                           pose: pose,
                           side: side,
                           mirrored: false)
            DuoEyeAssembly(center: .init(x: 0.67, y: 0.48),
                           pose: pose,
                           side: side,
                           mirrored: true)

            // Cheeks (translucent warm pads that bulge during happy / love).
            if pose.cheek > 0.02 {
                DuoCheek(center: .init(x: 0.17, y: 0.63), pose: pose)
                DuoCheek(center: .init(x: 0.83, y: 0.63), pose: pose)
            }

            // Beak sits on top of everything but under floating hearts / sparkles.
            DuoBeak(open: pose.beakOpen)

            if pose.hearts > 0.02 {
                DuoFloatingHearts(time: time, opacity: pose.hearts)
            }
            if pose.sparkle > 0.02 {
                DuoSparkles(time: time, opacity: pose.sparkle)
            }
        }
        .drawingGroup(opaque: false)
    }
}

// MARK: - Palette

private enum DuoPalette {
    static let containerGreen = Color(red: 0.345, green: 0.800, blue: 0.012)   // #58CC02
    static let faceGreen = Color(red: 0.537, green: 0.886, blue: 0.098)        // #89E219
    static let pupil = Color(red: 0.231, green: 0.235, blue: 0.251)            // #3B3C40
    static let beakUpper = Color(red: 1, green: 0.772, blue: 0.090)            // #FFC517
    static let beakLower = Color(red: 1, green: 0.561, blue: 0.098)            // #FF8F19
    static let eyeWhite = Color.white
    static let cheek = Color(red: 1, green: 0.431, blue: 0.431).opacity(0.55)
    static let heart = Color(red: 1, green: 0.361, blue: 0.498)
    static let sparkle = Color(red: 1, green: 0.933, blue: 0.459)
}

// MARK: - Head silhouette

/// A tuft-topped head: five peaks across the top with a rounded body. The
/// shape is drawn once at frame 0 and never recomputed per frame.
private struct DuoHeadShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        func pt(_ x: Double, _ y: Double) -> CGPoint {
            CGPoint(x: rect.minX + rect.width * x, y: rect.minY + rect.height * y)
        }
        // Start on the left side, below the first tuft.
        p.move(to: pt(0.08, 0.38))
        // Up to the small left ear tuft.
        p.addCurve(to: pt(0.15, 0.14),
                   control1: pt(0.07, 0.28), control2: pt(0.09, 0.17))
        // Down into the first valley.
        p.addCurve(to: pt(0.24, 0.22),
                   control1: pt(0.19, 0.18), control2: pt(0.21, 0.22))
        // Up to the tall left tuft.
        p.addCurve(to: pt(0.35, 0.04),
                   control1: pt(0.26, 0.14), control2: pt(0.30, 0.05))
        // Down into the central valley.
        p.addCurve(to: pt(0.50, 0.14),
                   control1: pt(0.40, 0.10), control2: pt(0.45, 0.17))
        // Up to the tall right tuft.
        p.addCurve(to: pt(0.65, 0.04),
                   control1: pt(0.55, 0.17), control2: pt(0.60, 0.10))
        // Down into the right valley.
        p.addCurve(to: pt(0.76, 0.22),
                   control1: pt(0.70, 0.05), control2: pt(0.74, 0.14))
        // Up to the small right ear tuft.
        p.addCurve(to: pt(0.85, 0.14),
                   control1: pt(0.79, 0.22), control2: pt(0.81, 0.18))
        // Down the right side.
        p.addCurve(to: pt(0.92, 0.38),
                   control1: pt(0.91, 0.17), control2: pt(0.93, 0.28))
        // Round down to bottom-right.
        p.addCurve(to: pt(0.88, 0.88),
                   control1: pt(0.95, 0.60), control2: pt(0.94, 0.80))
        // Across the bottom chest.
        p.addCurve(to: pt(0.12, 0.88),
                   control1: pt(0.74, 0.96), control2: pt(0.26, 0.96))
        // Round up the left side back to the start.
        p.addCurve(to: pt(0.08, 0.38),
                   control1: pt(0.06, 0.80), control2: pt(0.05, 0.60))
        p.closeSubpath()
        return p
    }
}

// MARK: - Eyes

private struct DuoEyeAssembly: View {
    /// Fractional center of the eye white within the frame.
    let center: CGPoint
    let pose: DuoPose
    let side: Double
    let mirrored: Bool

    private let eyeWidth: Double = 0.19
    private let eyeHeight: Double = 0.26

    var body: some View {
        let lid = mirrored ? pose.lidR : pose.lidL
        let w = eyeWidth * pose.eyeScale
        let h = eyeHeight * pose.eyeScale

        ZStack {
            // Eye white (slightly oversized so lid cover never shows a seam).
            Capsule()
                .fill(DuoPalette.eyeWhite)
                .frame(width: side * w, height: side * h)

            // Pupils blend between the three pupil styles based on target weights.
            DuoPupil(
                side: side,
                eyeW: w,
                eyeH: h,
                pose: pose,
                mirrored: mirrored
            )
            .clipShape(Capsule().inset(by: side * 0.004))
            .frame(width: side * w, height: side * h)
            .opacity(1 - 0.95 * lid)

            // Upper lid: a face-green rect that drops down to close the eye.
            // Drawn 2 units larger than the white to avoid an anti-alias halo.
            let lidH = side * (h + 0.012) * lid
            Rectangle()
                .fill(DuoPalette.faceGreen)
                .frame(width: side * (w + 0.012), height: max(0, lidH))
                .offset(y: -side * (h + 0.012) / 2 + lidH / 2)

            // Happy curve: an upside-down arc that fades in to replace the eye.
            if pose.happyCurve > 0.02 {
                DuoHappyArc(mirrored: mirrored)
                    .stroke(DuoPalette.pupil,
                            style: StrokeStyle(lineWidth: side * 0.028,
                                               lineCap: .round))
                    .frame(width: side * (w + 0.03), height: side * h * 0.9)
                    .opacity(pose.happyCurve)
            }
        }
        .position(x: side * center.x, y: side * center.y)
    }
}

private struct DuoPupil: View {
    let side: Double
    let eyeW: Double
    let eyeH: Double
    let pose: DuoPose
    let mirrored: Bool

    var body: some View {
        // Pupil travels within the eye white; convert fractional offsets to pts.
        let travelX = side * (eyeW - 0.09) / 2
        let travelY = side * (eyeH - 0.14) / 2
        let dx = travelX * pose.pupilDX * (mirrored ? 1 : 1)
        let dy = travelY * pose.pupilDY

        let normalOpacity = max(0, 1 - pose.heart - pose.swirl)

        ZStack {
            // Default dark pupil with a smaller lighter oval nudged to make
            // the signature Duo crescent (the lighter oval moves with the pupil
            // so the highlight stays on the pupil).
            ZStack {
                Ellipse()
                    .fill(DuoPalette.pupil)
                    .frame(width: side * 0.095, height: side * 0.17)
                Ellipse()
                    .fill(DuoPalette.eyeWhite)
                    .frame(width: side * 0.065, height: side * 0.13)
                    .offset(x: side * 0.025, y: -side * 0.015)
            }
            .scaleEffect(pose.pupilScale)
            .opacity(normalOpacity)

            // Heart pupil (love).
            if pose.heart > 0.02 {
                DuoHeart()
                    .fill(DuoPalette.heart)
                    .frame(width: side * 0.13, height: side * 0.12)
                    .opacity(pose.heart)
            }

            // X-mark pupil (dizzy).
            if pose.swirl > 0.02 {
                DuoCross()
                    .stroke(DuoPalette.pupil,
                            style: StrokeStyle(lineWidth: side * 0.022, lineCap: .round))
                    .frame(width: side * 0.10, height: side * 0.14)
                    .opacity(pose.swirl)
            }
        }
        .offset(x: dx, y: dy)
    }
}

/// Upside-down U, inflected at the ends to read as closed happy eyes.
private struct DuoHappyArc: Shape {
    let mirrored: Bool
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let y = rect.midY + rect.height * 0.15
        p.move(to: CGPoint(x: rect.minX, y: y))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: y),
                       control: CGPoint(x: rect.midX, y: rect.minY))
        return p
    }
}

private struct DuoHeart: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        p.move(to: CGPoint(x: rect.midX, y: rect.minY + h * 0.95))
        p.addCurve(to: CGPoint(x: rect.minX, y: rect.minY + h * 0.33),
                   control1: CGPoint(x: rect.minX + w * 0.1, y: rect.minY + h * 0.80),
                   control2: CGPoint(x: rect.minX, y: rect.minY + h * 0.55))
        p.addCurve(to: CGPoint(x: rect.midX, y: rect.minY + h * 0.25),
                   control1: CGPoint(x: rect.minX, y: rect.minY),
                   control2: CGPoint(x: rect.minX + w * 0.3, y: rect.minY))
        p.addCurve(to: CGPoint(x: rect.maxX, y: rect.minY + h * 0.33),
                   control1: CGPoint(x: rect.maxX - w * 0.3, y: rect.minY),
                   control2: CGPoint(x: rect.maxX, y: rect.minY))
        p.addCurve(to: CGPoint(x: rect.midX, y: rect.minY + h * 0.95),
                   control1: CGPoint(x: rect.maxX, y: rect.minY + h * 0.55),
                   control2: CGPoint(x: rect.maxX - w * 0.1, y: rect.minY + h * 0.80))
        p.closeSubpath()
        return p
    }
}

private struct DuoCross: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        return p
    }
}

// MARK: - Cheeks, beak, particles

private struct DuoCheek: View {
    let center: CGPoint
    let pose: DuoPose
    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            Ellipse()
                .fill(DuoPalette.cheek)
                .frame(width: side * 0.09 * pose.cheek, height: side * 0.055 * pose.cheek)
                .position(x: side * center.x, y: side * center.y)
                .opacity(pose.cheek)
        }
    }
}

private struct DuoBeak: View {
    let open: Double   // 0 closed, 1 fully open
    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            ZStack {
                // Upper (yellow) wider trapezoidal shape sits above and behind.
                DuoBeakUpper()
                    .fill(DuoPalette.beakUpper)
                    .frame(width: side * 0.22, height: side * 0.085)
                    .offset(y: -side * 0.012 * open)
                // Lower (orange) rounded dome sits in front, slightly smaller.
                DuoBeakLower()
                    .fill(DuoPalette.beakLower)
                    .frame(width: side * 0.17, height: side * 0.085 + side * 0.025 * open)
                    .offset(y: side * 0.038 + side * 0.015 * open)
            }
            .position(x: side * 0.5, y: side * 0.66)
        }
    }
}

/// A soft trapezoid with rounded corners — the top edge is narrower than the
/// bottom and both ends curve inward, matching the Duolingo beak profile.
private struct DuoBeakUpper: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let topInset = rect.width * 0.18
        let r = rect.height * 0.45
        p.move(to: CGPoint(x: rect.minX + topInset, y: rect.minY + r))
        p.addQuadCurve(to: CGPoint(x: rect.minX + topInset + r, y: rect.minY),
                       control: CGPoint(x: rect.minX + topInset, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - topInset - r, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX - topInset, y: rect.minY + r),
                       control: CGPoint(x: rect.maxX - topInset, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.minX + topInset, y: rect.minY + r),
                       control: CGPoint(x: rect.midX, y: rect.maxY + rect.height * 0.4))
        p.closeSubpath()
        return p
    }
}

/// Rounded orange dome: flat on top, bulging below.
private struct DuoBeakLower: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.minY),
                       control: CGPoint(x: rect.midX, y: rect.maxY + rect.height * 0.3))
        p.closeSubpath()
        return p
    }
}

/// Hearts rise with varied phases from the owl's face. Each heart fades in
/// and out with a bell shape; opacity gates them so they never pop.
private struct DuoFloatingHearts: View {
    let time: Double
    let opacity: Double
    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            Canvas { ctx, size in
                for i in 0..<4 {
                    let phase = DuoMotion.seeded(i, 1)
                    let p = DuoMotion.loop(time, period: 2.2, phase: phase)
                    let bell = sin(p * .pi)
                    let x = 0.5 + (DuoMotion.seeded(i, 2) - 0.5) * 0.5
                    let startY = 0.55
                    let y = startY - p * 0.30
                    let s = side * (0.045 + 0.01 * DuoMotion.seeded(i, 3))
                    let rect = CGRect(x: size.width * x - s / 2,
                                      y: size.height * y - s / 2,
                                      width: s, height: s)
                    let path = DuoHeart().path(in: rect)
                    ctx.opacity = opacity * bell
                    ctx.fill(path, with: .color(DuoPalette.heart))
                }
            }
            .allowsHitTesting(false)
        }
    }
}

/// Short-lived sparkles that bloom around the owl's head on surprise.
private struct DuoSparkles: View {
    let time: Double
    let opacity: Double
    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            Canvas { ctx, size in
                for i in 0..<6 {
                    let phase = DuoMotion.seeded(i, 4)
                    let p = DuoMotion.loop(time, period: 1.1, phase: phase)
                    let bell = sin(p * .pi)
                    let angle = 2 * .pi * DuoMotion.seeded(i, 5)
                    let radius = 0.28 + 0.08 * DuoMotion.seeded(i, 6)
                    let x = 0.5 + cos(angle) * radius
                    let y = 0.42 + sin(angle) * radius * 0.9
                    let s = side * (0.03 + 0.015 * DuoMotion.seeded(i, 7)) * bell
                    let rect = CGRect(x: size.width * x - s / 2,
                                      y: size.height * y - s / 2,
                                      width: s, height: s)
                    ctx.opacity = opacity * bell
                    ctx.fill(DuoSparkle().path(in: rect), with: .color(DuoPalette.sparkle))
                }
            }
            .allowsHitTesting(false)
        }
    }
}

private struct DuoSparkle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        p.move(to: CGPoint(x: c.x, y: c.y - r))
        p.addQuadCurve(to: CGPoint(x: c.x + r, y: c.y), control: c)
        p.addQuadCurve(to: CGPoint(x: c.x, y: c.y + r), control: c)
        p.addQuadCurve(to: CGPoint(x: c.x - r, y: c.y), control: c)
        p.addQuadCurve(to: CGPoint(x: c.x, y: c.y - r), control: c)
        p.closeSubpath()
        return p
    }
}
