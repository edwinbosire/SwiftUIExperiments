import SwiftUI

/// The system launch screen stays static; this short scene runs once per window
/// after SwiftUI is ready, with the catalogue already mounted underneath.
struct ExperimentLaunchView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var finished = false

    private var bypassSplash: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-skip-splash") ||
        DemoLayoutTesting.argument("-demo-test-feature") != nil
        #else
        false
        #endif
    }

    private var showsSplash: Bool { !finished && !reduceMotion && !bypassSplash }

    var body: some View {
        ZStack {
            ContentView()
                .allowsHitTesting(!showsSplash)
                .accessibilityHidden(showsSplash)
            if showsSplash {
                FloatingExperimentSplash { finished = true }
                    .zIndex(1)
            }
        }
        .onChange(of: reduceMotion, initial: true) { _, reduced in
            if reduced { finished = true }
        }
    }
}

struct FloatingExperimentSplash: View {
    var fadesOut = true
    let onFinished: () -> Void
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var startedAt: ContinuousClock.Instant?
    @State private var accumulated: Double = 0
    @State private var completed = false

    private var inspectionTime: Double? {
        #if DEBUG
        if let value = DemoLayoutTesting.argument("-splash-test-time").flatMap(Double.init), value.isFinite {
            return min(max(value, 0), FloatingExperimentMotion.duration)
        }
        #endif
        return nil
    }

    var body: some View {
        TimelineView(.animation(paused: scenePhase != .active || inspectionTime != nil || completed || reduceMotion)) { _ in
            let time = reduceMotion || completed ? FloatingExperimentMotion.duration : inspectionTime ?? elapsed
            FloatingExperimentSplashFrame(time: time)
                .opacity(fadesOut && inspectionTime == nil ? 1 - seg(time, 2400, FloatingExperimentMotion.duration) : 1)
                .onChange(of: time >= FloatingExperimentMotion.duration, initial: true) { _, done in
                    if done && inspectionTime == nil && !completed {
                        completed = true
                        startedAt = nil
                        accumulated = FloatingExperimentMotion.duration
                        onFinished()
                    }
                }
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            if phase == .active {
                if startedAt == nil && !completed && !reduceMotion { startedAt = .now }
            } else {
                accumulated = elapsed
                startedAt = nil
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("UI Experiments")
        .accessibilityIdentifier("floating-experiment-splash")
    }

    private var elapsed: Double {
        guard let startedAt else { return accumulated }
        let delta = startedAt.duration(to: .now).components
        return accumulated + Double(delta.seconds) * 1000 + Double(delta.attoseconds) / 1e15
    }
}

/// A deterministic frame shared by the live splash, previews and offline renders.
struct FloatingExperimentSplashFrame: View {
    let time: Double

    var body: some View {
        GeometryReader { geometry in
            let side = max(1, min(360, geometry.size.width - 32, geometry.size.height * 0.62))
            VStack(spacing: 16) {
                FloatingExperimentArtwork(time: time)
                    .frame(width: side, height: side)
                    .accessibilityHidden(true)
                VStack(spacing: 10) {
                    Text("UI EXPERIMENTS")
                        .font(.system(.caption, design: .monospaced, weight: .medium))
                        .tracking(3)
                    Text("A little room to play.")
                        .font(.system(.title3, design: .serif))
                        .foregroundStyle(CataloguePalette.muted)
                }
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .foregroundStyle(CataloguePalette.ink)
        .background(CataloguePalette.paper.ignoresSafeArea())
        .preferredColorScheme(.light)
    }
}

#Preview("Floating experiment · launch") {
    ExperimentLaunchView()
}

#Preview("Floating experiment · lifted") {
    FloatingExperimentSplashFrame(time: 950)
}
