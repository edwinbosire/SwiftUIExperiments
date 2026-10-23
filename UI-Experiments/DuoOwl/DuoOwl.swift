import SwiftUI

// A tribute to the Duolingo owl icon reimagined as a living, tappable mascot.
// All geometry is defined in a 1x1 unit square so the artwork scales freely.
// Numbers follow the project's motion method: small amplitudes, long periods,
// strong curves, and nothing moves while the view is off screen.

enum DuoReaction: Int, CaseIterable, Identifiable {
    case idle, happy, surprised, love, dizzy, sleepy

    var id: Self { self }

    var title: String {
        switch self {
        case .idle: "Idle"
        case .happy: "Happy"
        case .surprised: "Surprised"
        case .love: "Love"
        case .dizzy: "Dizzy"
        case .sleepy: "Sleepy"
        }
    }

    var symbol: String {
        switch self {
        case .idle: "eye"
        case .happy: "face.smiling"
        case .surprised: "sparkles"
        case .love: "heart.fill"
        case .dizzy: "arrow.2.circlepath"
        case .sleepy: "moon.fill"
        }
    }

    /// Target channel values the artwork drifts toward when this reaction is active.
    var target: DuoReactionTarget {
        switch self {
        case .idle: DuoReactionTarget()
        case .happy: DuoReactionTarget(pupilDY: 0.1, happyCurve: 1, cheek: 1, lift: -0.012, squashY: 1.03)
        case .surprised: DuoReactionTarget(eyeScale: 1.22, pupilScale: 0.45, lift: -0.02, squashY: 0.94, sparkle: 1)
        case .love: DuoReactionTarget(pupilDY: 0.05, happyCurve: 0.25, heart: 1, cheek: 0.55, hearts: 1)
        case .dizzy: DuoReactionTarget(lid: 0.1, swirl: 1, dizzyRock: 1)
        case .sleepy: DuoReactionTarget(pupilDY: 0.35, lid: 0.62, cheek: 0.25, lift: 0.01, squashY: 0.98)
        }
    }

    /// How long each reaction holds before the artwork drifts back toward idle.
    var hold: Double {
        switch self {
        case .idle: .infinity
        case .happy, .surprised: 2.2
        case .love: 3.0
        case .dizzy: 2.6
        case .sleepy: 3.4
        }
    }
}

/// Mutable blend channels. The idle layer always adds breathing, blinks and
/// gaze on top of whichever reaction target is active.
struct DuoReactionTarget {
    var pupilDX: Double = 0        // -1..1, fraction of available travel inside the eye white
    var pupilDY: Double = 0
    var lid: Double = 0            // 0 open, 1 closed
    var happyCurve: Double = 0     // 0 normal eye, 1 upside-down arc
    var eyeScale: Double = 1       // width/height of eye white
    var pupilScale: Double = 1
    var heart: Double = 0          // 0..1 heart-shaped pupil opacity
    var swirl: Double = 0          // 0..1 X-shaped pupil opacity
    var cheek: Double = 0          // 0..1 raised cheek bulge
    var tilt: Double = 0           // additional head tilt in degrees
    var lift: Double = 0           // additional vertical offset
    var squashY: Double = 1        // vertical scale on the whole owl
    var sparkle: Double = 0        // sparkle burst opacity
    var hearts: Double = 0         // floating hearts opacity
    var dizzyRock: Double = 0      // enables a slow sinusoidal tilt
}

/// Fully-resolved pose rendered by the artwork each frame.
struct DuoPose {
    var pupilDX: Double
    var pupilDY: Double
    var lidL: Double
    var lidR: Double
    var happyCurve: Double
    var eyeScale: Double
    var pupilScale: Double
    var heart: Double
    var swirl: Double
    var cheek: Double
    var tilt: Double
    var lift: Double
    var squashY: Double
    var sparkle: Double
    var hearts: Double
    var beakOpen: Double
}

// MARK: - Motion engine

enum DuoMotion {
    /// Smooth triangle-ish wave in [-1, 1] using a cosine for comfort.
    static func wave(_ t: Double, period: Double, phase: Double = 0) -> Double {
        cos((t / period + phase) * 2 * .pi)
    }

    /// 0..1 linear progress through a loop with optional phase offset.
    static func loop(_ t: Double, period: Double, phase: Double = 0) -> Double {
        var v = (t / period + phase).truncatingRemainder(dividingBy: 1)
        if v < 0 { v += 1 }
        return v
    }

    /// Smoothstep ease-in-out.
    static func smooth(_ x: Double) -> Double {
        let v = min(max(x, 0), 1)
        return v * v * (3 - 2 * v)
    }

    /// Ease-out quartic, for arrivals and reopenings.
    static func easeOut(_ x: Double) -> Double {
        let v = min(max(x, 0), 1)
        return 1 - pow(1 - v, 4)
    }

    /// Linear interpolate.
    static func mix(_ a: Double, _ b: Double, _ t: Double) -> Double { a + (b - a) * t }

    /// Deterministic seeded random in [0, 1) from an integer key.
    static func seeded(_ i: Int, _ channel: Int = 0) -> Double {
        var v = UInt64(bitPattern: Int64(i)) &* 0x9E3779B97F4A7C15
            &+ UInt64(bitPattern: Int64(channel)) &* 0xD1B54A32D192ED03
            &+ 0xC2B2AE3D27D4EB4F
        v = (v ^ (v >> 30)) &* 0xBF58476D1CE4E5B9
        v = (v ^ (v >> 27)) &* 0x94D049BB133111EB
        v ^= v >> 31
        return Double(v >> 11) / Double(1 << 53)
    }
}

/// Blinks happen on an irregular cadence so repeats never feel mechanical.
struct DuoBlinkTrack {
    let seed: UInt64

    func amount(at time: Double) -> Double {
        let cadence = 2.6
        let clock = max(0, time) + random(0, 1) * 60
        let event = Int(floor(clock / cadence))
        let eventStart = (Double(event) + random(event, 2) * 0.75) * cadence
        let elapsed = clock - eventStart
        guard elapsed >= 0 else { return 0 }
        // Close in 110 ms, hold 40 ms, reopen in 190 ms with ease-out.
        let close = 0.11
        let hold = 0.04
        let open = 0.19
        if elapsed < close {
            return DuoMotion.smooth(elapsed / close)
        } else if elapsed < close + hold {
            return 1
        } else if elapsed < close + hold + open {
            let p = (elapsed - close - hold) / open
            return 1 - DuoMotion.easeOut(p)
        }
        return 0
    }

    /// Rare double-blink: a short second close soon after the primary.
    func isDoubleBlink(at time: Double) -> Bool {
        let cadence = 2.6
        let event = Int(floor(max(0, time) / cadence))
        return random(event, 3) < 0.18
    }

    private func random(_ event: Int, _ channel: UInt64) -> Double {
        var v = seed &+ UInt64(bitPattern: Int64(event)) &* 0x9E3779B97F4A7C15
            &+ channel &* 0xD1B54A32D192ED03
        v = (v ^ (v >> 30)) &* 0xBF58476D1CE4E5B9
        v = (v ^ (v >> 27)) &* 0x94D049BB133111EB
        v ^= v >> 31
        return Double(v >> 11) / Double(1 << 53)
    }
}

// MARK: - Pose composition

extension DuoPose {
    /// Compose the frame pose from the current/previous reaction, the global
    /// clock, the gaze target the user is pointing at, and the blink track.
    static func compose(
        time: Double,
        reaction: DuoReaction,
        previous: DuoReaction,
        reactionProgress: Double,
        gazeTarget: CGPoint?,
        blinkTrack: DuoBlinkTrack,
        reduceMotion: Bool
    ) -> DuoPose {
        let p = DuoMotion.smooth(reactionProgress)
        let a = previous.target
        let b = reaction.target
        func mix(_ ka: KeyPath<DuoReactionTarget, Double>) -> Double {
            DuoMotion.mix(a[keyPath: ka], b[keyPath: ka], p)
        }
        let targetDX = mix(\.pupilDX)
        let targetDY = mix(\.pupilDY)
        let targetLid = mix(\.lid)
        let happyCurve = mix(\.happyCurve)
        let eyeScale = mix(\.eyeScale)
        let pupilScale = mix(\.pupilScale)
        let heart = mix(\.heart)
        let swirl = mix(\.swirl)
        let cheek = mix(\.cheek)
        let addedTilt = mix(\.tilt)
        let addedLift = mix(\.lift)
        let squashY = mix(\.squashY)
        let sparkle = mix(\.sparkle)
        let hearts = mix(\.hearts)
        let dizzyRock = mix(\.dizzyRock)

        // Idle layer: breathing, head tilt, gentle gaze drift and blinks.
        let breath = reduceMotion ? 0 : -0.5 + 0.5 * cos(time * 2 * .pi / 3.6)
        let idleTilt = reduceMotion ? 0 : 3 * sin(time * 2 * .pi / 5.2)
        let dizzyTilt = dizzyRock * 7 * sin(time * 2 * .pi / 0.9)
        let idleGazeX = reduceMotion ? 0 : 0.18 * sin(time * 2 * .pi / 4.7 + 0.4)
        let idleGazeY = reduceMotion ? 0 : 0.12 * sin(time * 2 * .pi / 6.1 + 1.2)

        // Gaze: track the tap point if provided, otherwise drift idly.
        var pupilDX = targetDX
        var pupilDY = targetDY
        if let gaze = gazeTarget {
            // gaze.x/y are already in [-1, 1] relative to the owl's face.
            let gx = min(max(gaze.x, -1), 1)
            let gy = min(max(gaze.y, -1), 1)
            // Pupils reach ~80% of their range toward the gaze target.
            pupilDX = DuoMotion.mix(pupilDX, 0.8 * gx, 0.85)
            pupilDY = DuoMotion.mix(pupilDY, 0.8 * gy, 0.85)
        } else {
            pupilDX += idleGazeX * (1 - 0.6 * (heart + swirl + happyCurve))
            pupilDY += idleGazeY * (1 - 0.6 * (heart + swirl + happyCurve))
        }

        let blink = reduceMotion ? 0 : blinkTrack.amount(at: time)
        let lidL = min(1, targetLid + blink)
        let lidR = min(1, targetLid + blink)

        return DuoPose(
            pupilDX: pupilDX,
            pupilDY: pupilDY,
            lidL: lidL,
            lidR: lidR,
            happyCurve: happyCurve,
            eyeScale: eyeScale,
            pupilScale: pupilScale,
            heart: heart,
            swirl: swirl,
            cheek: cheek,
            tilt: idleTilt + addedTilt + dizzyTilt,
            lift: 0.008 * breath + addedLift,
            squashY: squashY,
            sparkle: sparkle,
            hearts: hearts,
            beakOpen: 0.45 * sparkle   // small open mouth on surprise
        )
    }
}
