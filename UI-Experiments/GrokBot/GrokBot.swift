import SwiftUI

enum GrokBot: Int, CaseIterable, Identifiable {
    case cloud, pink, brown, purple, red, amber, teal, blue, hexagon

    var id: Self { self }

    var name: String {
        switch self {
        case .cloud: "Green cloud"
        case .pink: "Pink blob"
        case .brown: "Brown circle"
        case .purple: "Purple droplet"
        case .red: "Red blob"
        case .amber: "Amber circle"
        case .teal: "Teal circle"
        case .blue: "Blue square"
        case .hexagon: "Orange hexagon"
        }
    }

    // Colors sampled from the supplied video, converted to sRGB.
    var color: Color {
        switch self {
        case .cloud: Color(red: 0, green: 0.768, blue: 0.416)
        case .pink: Color(red: 1, green: 0.151, blue: 0.606)
        case .brown: Color(red: 0.546, green: 0.345, blue: 0.176)
        case .purple: Color(red: 0.548, green: 0.294, blue: 1)
        case .red: Color(red: 1, green: 0.105, blue: 0.227)
        case .amber: Color(red: 1, green: 0.566, blue: 0)
        case .teal: Color(red: 0, green: 0.705, blue: 0.621)
        case .blue: Color(red: 0.053, green: 0.481, blue: 1)
        case .hexagon: Color(red: 1, green: 0.383, blue: 0)
        }
    }

    var size: CGSize {
        switch self {
        case .cloud: CGSize(width: 78, height: 63)
        case .pink: CGSize(width: 59, height: 55)
        case .brown: CGSize(width: 57, height: 58)
        case .purple: CGSize(width: 46, height: 55)
        case .red: CGSize(width: 75, height: 75)
        case .amber: CGSize(width: 84, height: 84)
        case .teal: CGSize(width: 56, height: 56)
        case .blue: CGSize(width: 62, height: 62)
        case .hexagon: CGSize(width: 74, height: 80)
        }
    }

    /// The video's screen, measured in a 390 × 844 coordinate space.
    private var origin: CGPoint {
        switch self {
        case .cloud: CGPoint(x: 87, y: 187)
        case .pink: CGPoint(x: 227, y: 160)
        case .brown: CGPoint(x: 350, y: 272)
        case .purple: CGPoint(x: 13, y: 337)
        case .red: CGPoint(x: 400, y: 425)
        case .amber: CGPoint(x: 4, y: 500)
        case .teal: CGPoint(x: 368, y: 583)
        case .blue: CGPoint(x: 66, y: 651)
        case .hexagon: CGPoint(x: 221, y: 641)
        }
    }

    private var travel: CGSize {
        switch self {
        case .cloud: CGSize(width: 35, height: -47)
        case .pink: CGSize(width: 40, height: 40)
        case .brown: CGSize(width: 36, height: 44)
        case .purple: CGSize(width: 25, height: -50)
        case .red: CGSize(width: 0, height: 55)
        case .amber: CGSize(width: -8, height: -58)
        case .teal: CGSize(width: -40, height: 38)
        case .blue: CGSize(width: -33, height: -45)
        case .hexagon: CGSize(width: -51, height: 24)
        }
    }

    func position(at time: Double, in size: CGSize) -> CGPoint {
        // The first 9.617 seconds follow the reference drift. A long, continuous
        // return keeps the bots floating after the supplied clip has ended.
        let duration = 9.617
        let t = time.truncatingRemainder(dividingBy: duration * 4) / duration
        let progress: Double
        if t <= 1 {
            progress = t
        } else if t <= 3 {
            let u = (t - 1) / 2
            progress = 1 + 2 * u - 12 * u * u + 8 * u * u * u
        } else {
            progress = t - 4
        }
        return CGPoint(
            x: (origin.x + travel.width * progress) / 390 * size.width,
            y: (origin.y + travel.height * progress) / 844 * size.height
        )
    }

    func rotation(at time: Double) -> Double {
        let phase = Double(rawValue) * 0.71
        switch self {
        case .blue: return 7 * cos(time * 0.88)
        case .hexagon: return 5 * sin(time * 0.73 + 0.3)
        case .cloud: return -4 * sin(time * 0.63)
        default: return 4 * sin(time * 0.76 + phase)
        }
    }

    var reactionOffset: Double { Double(rawValue) * 0.43 }
}

enum GrokReaction: String, CaseIterable, Identifiable {
    case automatic = "Auto"
    case curious = "Curious"
    case happy = "Happy"
    case surprised = "Surprised"
    case sleepy = "Sleepy"
    case blink = "Blink"

    var id: Self { self }

    var symbol: String {
        switch self {
        case .automatic: "play.fill"
        case .curious: "eyes"
        case .happy: "face.smiling"
        case .surprised: "sparkle"
        case .sleepy: "moon"
        case .blink: "eye"
        }
    }
}

/// Each white eye is a capsule. Position, size, and tilt carry the expression;
/// there are no pupils or mouths in the reference.
struct GrokEyePose {
    var x: Double = 0.53
    var y: Double = 0.56
    var width: Double = 0.14
    var height: Double = 0.35
    var separation: Double = 0.25
    var leftTilt: Double = 0.27
    var rightTilt: Double = 0.27

    static let relaxed = GrokEyePose()
    static let lookingRight = GrokEyePose(x: 0.83, y: 0.45, width: 0.075, height: 0.18, separation: 0.18, leftTilt: -0.15, rightTilt: -0.15)
    static let delighted = GrokEyePose(x: 0.50, y: 0.48, width: 0.105, height: 0.29, separation: 0.24, leftTilt: -0.57, rightTilt: 0.39)
    static let chevron = GrokEyePose(x: 0.45, y: 0.45, width: 0.09, height: 0.27, separation: 0.23, leftTilt: 0.55, rightTilt: -0.40)
    static let wide = GrokEyePose(x: 0.39, y: 0.54, width: 0.205, height: 0.27, separation: 0.30, leftTilt: 0, rightTilt: 0)
    static let leaningLeft = GrokEyePose(x: 0.43, y: 0.57, width: 0.16, height: 0.40, separation: 0.29, leftTilt: -0.25, rightTilt: -0.25)
    static let lowRight = GrokEyePose(x: 0.60, y: 0.69, width: 0.16, height: 0.31, separation: 0.30, leftTilt: 0.27, rightTilt: 0.27)

    func interpolated(to other: Self, amount: Double) -> Self {
        let t = min(max(amount, 0), 1)
        func mix(_ a: Double, _ b: Double) -> Double { a + (b - a) * t }
        return Self(x: mix(x, other.x), y: mix(y, other.y),
                    width: mix(width, other.width), height: mix(height, other.height),
                    separation: mix(separation, other.separation),
                    leftTilt: mix(leftTilt, other.leftTilt), rightTilt: mix(rightTilt, other.rightTilt))
    }

    static func pose(for bot: GrokBot, reaction: GrokReaction, time: Double,
                     autonomousReactions: GrokAutonomousReactions? = nil) -> Self {
        let localTime = max(0, time)
        let track = autonomousReactions ?? GrokAutonomousReactions(seed: UInt64(bot.rawValue))
        let expressionTime = track.animationTime(at: localTime)
        var pose: Self
        switch reaction {
        case .automatic: pose = track.pose(at: localTime)
        case .curious:
            pose = .lookingRight
            pose.x = 0.61 + 0.16 * sin(expressionTime * 1.7)
            pose.y = 0.47 + 0.05 * cos(expressionTime * 1.7)
        case .happy:
            pose = .chevron
            pose.y += 0.025 * sin(expressionTime * 5)
        case .surprised:
            pose = .wide
            pose.x = 0.5
            pose.width = 0.19
            pose.height = 0.36
        case .sleepy:
            pose = .relaxed
            pose.height = 0.055 + 0.022 * (1 + sin(expressionTime * 1.3))
            pose.width = 0.18
            pose.leftTilt = 0
            pose.rightTilt = 0
        case .blink:
            pose = .relaxed
        }

        if reaction == .automatic || reaction == .blink || reaction == .curious {
            pose.height *= 1 - 0.94 * track.blinkAmount(at: localTime, frequent: reaction == .blink)
        }
        return pose
    }

}

/// A private random stream for one mascot. Sampling the same time always gives
/// the same pose, so redraws never introduce jitter. Event times are irregular
/// and do not reset on the old shared 10.5-second reference loop.
struct GrokAutonomousReactions {
    let seed: UInt64

    func animationTime(at time: Double) -> Double {
        time * (0.8 + random(0, 20) * 0.4) + random(0, 21) * 20
    }

    func pose(at time: Double) -> GrokEyePose {
        let cadence = 1.8 + random(0, 10) * 2.4
        let clock = max(0, time) + random(0, 11) * 60
        let event = currentEvent(at: clock, cadence: cadence, channel: 0)
        let start = eventStart(event, cadence: cadence, channel: 0)
        let transition = 0.2 + random(event, 1) * 0.25
        let progress = min(max((clock - start) / transition, 0), 1)
        return expression(event - 1).interpolated(
            to: expression(event), amount: progress * progress * (3 - 2 * progress)
        )
    }

    func blinkAmount(at time: Double, frequent: Bool = false) -> Double {
        let cadence = frequent ? 0.9 + random(0, 12) : 2.2 + random(0, 12) * 3.8
        let clock = max(0, time) + random(0, 13) * 60
        let event = currentEvent(at: clock, cadence: cadence, channel: 14)
        let elapsed = clock - eventStart(event, cadence: cadence, channel: 14)
        let duration = 0.16 + random(event, 15) * 0.12
        let progress = min(max(elapsed / duration, 0), 1)
        let pulse = sin(progress * .pi)
        return pulse * pulse
    }

    private func currentEvent(at time: Double, cadence: Double, channel: UInt64) -> Int {
        let event = Int(floor(time / cadence))
        return time >= eventStart(event, cadence: cadence, channel: channel) ? event : event - 1
    }

    private func eventStart(_ event: Int, cadence: Double, channel: UInt64) -> Double {
        // Bounded jitter keeps event starts ordered while varying the holds.
        (Double(event) + random(event, channel) * 0.65) * cadence
    }

    private func expression(_ event: Int) -> GrokEyePose {
        var pose: GrokEyePose
        switch Int(random(event, 2) * 8) {
        case 0: pose = .relaxed
        case 1: pose = .lookingRight
        case 2: pose = .delighted
        case 3: pose = .chevron
        case 4: pose = .wide
        case 5: pose = .leaningLeft
        case 6: pose = .lowRight
        default:
            pose = .relaxed
            pose.height = 0.11
            pose.leftTilt = 0
            pose.rightTilt = 0
        }
        if random(event, 3) < 0.5 {
            pose.x = 1 - pose.x
            let left = pose.leftTilt
            pose.leftTilt = -pose.rightTilt
            pose.rightTilt = -left
        }
        pose.x += (random(event, 4) - 0.5) * 0.06
        pose.y += (random(event, 5) - 0.5) * 0.06
        pose.width *= 0.9 + random(event, 6) * 0.18
        pose.height *= 0.85 + random(event, 7) * 0.28
        return pose
    }

    private func random(_ event: Int, _ channel: UInt64) -> Double {
        var value = seed &+ UInt64(bitPattern: Int64(event)) &* 0x9E3779B97F4A7C15
            &+ channel &* 0xD1B54A32D192ED03
        value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
        value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
        value ^= value >> 31
        return Double(value >> 11) / 9_007_199_254_740_992
    }
}
