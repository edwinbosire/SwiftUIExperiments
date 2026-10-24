import SwiftUI

/// A living Duolingo-style owl icon that breathes, blinks, follows your taps,
/// and plays a reaction when you tap its body. The reaction row at the bottom
/// also triggers reactions directly.
struct DuoOwlDemoView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var origin = Date()
    @State private var pausedAt: Date?
    @State private var suspension: TimeInterval = 0
    @State private var reaction: DuoReaction = .idle
    @State private var previousReaction: DuoReaction = .idle
    @State private var reactionStart: Double = 0
    @State private var reactionExpiresAt: Double?
    @State private var gaze: GazeState?
    @State private var blinkTrack = DuoBlinkTrack(seed: UInt64.random(in: .min ... .max))

    /// Where the owl is currently looking in its own coordinate space.
    private struct GazeState {
        var target: CGPoint   // in [-1, 1] relative to the face center
        var expiresAt: Double
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("Say hi to Duo")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                        Text("Tap Duo to change his mood. Tap around him and his eyes will follow.")
                            .font(.subheadline)
                            .foregroundStyle(DuoOwlPaper.ink.opacity(0.65))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .multilineTextAlignment(.center)
                    owlStage
                        .frame(height: min(420, max(180, geometry.size.height * 0.52)))
                    reactionRow
                }
                .foregroundStyle(DuoOwlPaper.ink)
                .padding(20)
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
            .accessibilityIdentifier("duo-owl-scroll")
        }
        .background(DuoOwlPaper.color.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                }
                .accessibilityLabel("Back to experiments")
                .accessibilityIdentifier("close-duo-owl-demo")
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("Duo")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: scenePhase) { _, phase in
            if phase != .active, pausedAt == nil {
                pausedAt = Date()
            } else if phase == .active, let paused = pausedAt {
                suspension += Date().timeIntervalSince(paused)
                pausedAt = nil
            }
        }
    }

    private var owlStage: some View {
        GeometryReader { geometry in
            let side = max(1, min(geometry.size.width - 32, geometry.size.height * 0.9))
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let frame = CGRect(x: center.x - side / 2, y: center.y - side / 2, width: side, height: side)
            TimelineView(.animation(minimumInterval: 1.0 / 60,
                                    paused: reduceMotion || scenePhase != .active)) { timeline in
                let now = max(0, (pausedAt ?? timeline.date).timeIntervalSince(origin) - suspension)
                DuoOwlArtwork(pose: currentPose(at: now), time: now)
                    .frame(width: side, height: side)
                    .position(center)
                    .onChange(of: timeline.date) { _, _ in tick(now: now) }
            }
            .contentShape(Rectangle())
            .onTapGesture { location in
                handleTap(at: location, in: geometry.size, owlFrame: frame)
            }
        }
        .accessibilityIdentifier("duo-owl-stage")
    }

    // MARK: - Pose

    private func currentPose(at time: Double) -> DuoPose {
        let elapsed = max(0, time - reactionStart)
        let p = min(1, elapsed / 0.45)
        let gazeTarget = gaze.flatMap { time < $0.expiresAt ? $0.target : nil }
        return DuoPose.compose(
            time: time,
            reaction: reaction,
            previous: previousReaction,
            reactionProgress: p,
            gazeTarget: gazeTarget,
            blinkTrack: blinkTrack,
            reduceMotion: reduceMotion
        )
    }

    private func tick(now: Double) {
        if let expires = reactionExpiresAt, reaction != .idle, now >= expires {
            trigger(.idle, at: now)
        }
    }

    // MARK: - Interaction

    private func handleTap(at location: CGPoint, in size: CGSize, owlFrame: CGRect) {
        let now = elapsed()
        if owlFrame.insetBy(dx: -8, dy: -8).contains(location) {
            trigger(nextReaction(), at: now)
        } else {
            let dx = (location.x - owlFrame.midX) / (owlFrame.width / 2)
            let dy = (location.y - owlFrame.midY) / (owlFrame.height / 2)
            gaze = GazeState(target: CGPoint(x: dx, y: dy), expiresAt: now + 1.8)
        }
    }

    private func trigger(_ next: DuoReaction, at time: Double) {
        previousReaction = reaction
        reaction = next
        reactionStart = time
        reactionExpiresAt = next == .idle ? nil : time + next.hold
    }

    private func nextReaction() -> DuoReaction {
        let order: [DuoReaction] = [.happy, .surprised, .love, .dizzy, .sleepy]
        if let i = order.firstIndex(of: reaction) {
            return order[(i + 1) % order.count]
        }
        return .happy
    }

    private func elapsed() -> Double {
        max(0, Date().timeIntervalSince(origin) - suspension)
    }

    // MARK: - Chrome

    private var reactionRow: some View {
        LazyVGrid(columns: dynamicTypeSize.isAccessibilitySize
                  ? [GridItem(.flexible())]
                  : [GridItem(.adaptive(minimum: 80), spacing: 8)], spacing: 8) {
            ForEach(DuoReaction.allCases) { option in
                Button {
                    trigger(option, at: elapsed())
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: option.symbol)
                            .font(.system(size: 15, weight: .semibold))
                        Text(option.title)
                            .font(.system(.caption2, design: .rounded, weight: .medium))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .foregroundStyle(reaction == option ? .white : DuoOwlPaper.ink.opacity(0.78))
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(reaction == option
                                  ? Color(red: 0.345, green: 0.800, blue: 0.012)
                                  : DuoOwlPaper.chip)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(option.title) reaction")
                .accessibilityIdentifier("duo-reaction-\(option.title.lowercased())")
                .accessibilityAddTraits(reaction == option ? .isSelected : [])
            }
        }
    }
}

private enum DuoOwlPaper {
    static let color = Color(red: 0.956, green: 0.976, blue: 0.945)
    static let ink = Color(red: 0.14, green: 0.19, blue: 0.11)
    static let chip = Color.white.opacity(0.9)
}

#Preview {
    NavigationStack {
        DuoOwlDemoView()
    }
}
