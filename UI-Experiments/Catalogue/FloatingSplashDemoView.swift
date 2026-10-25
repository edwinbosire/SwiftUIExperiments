import SwiftUI

struct FloatingSplashDemoView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var replayID = 0
    @State private var isPlaying = true
    @State private var isLooping = false

    var body: some View {
        FloatingExperimentSplash(fadesOut: false) {
            if isLooping && !reduceMotion {
                replay()
            } else {
                isPlaying = false
            }
        }
            .id(replayID)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 12) {
                    Toggle("Loop animation", isOn: $isLooping)
                        .tint(CataloguePalette.ink)
                        .disabled(reduceMotion)
                        .accessibilityIdentifier("floating-splash-loop")
                        .accessibilityHint("Repeats automatically. Turn off to finish the current animation.")
                    if reduceMotion {
                        Text("Reduce Motion is on. Showing the settled artwork.")
                            .font(.footnote)
                            .foregroundStyle(CataloguePalette.muted)
                            .multilineTextAlignment(.center)
                    }
                    Button {
                        replay()
                    } label: {
                        Label("Replay animation", systemImage: "arrow.clockwise")
                            .font(.body.weight(.medium))
                            .frame(maxWidth: .infinity, minHeight: 48)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(CataloguePalette.ink)
                    .disabled(isPlaying || reduceMotion)
                    .accessibilityIdentifier("floating-splash-replay")
                    .accessibilityValue(reduceMotion ? "Reduce Motion is on" : isPlaying ? "Playing" : "Ready")
                }
                .frame(maxWidth: 360)
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
                .background(CataloguePalette.paper)
            }
            .background(CataloguePalette.paper.ignoresSafeArea())
            .navigationTitle("Floating splash")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar(.visible, for: .navigationBar)
            .toolbarBackground(CataloguePalette.paper, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Label("Experiments", systemImage: "chevron.left")
                    }
                    .accessibilityLabel("Back to experiments")
                    .accessibilityIdentifier("close-floating-splash-demo")
                }
            }
            .tint(CataloguePalette.ink)
            .preferredColorScheme(.light)
            .onChange(of: isLooping) { _, looping in
                if looping && !isPlaying && !reduceMotion { replay() }
            }
            .onChange(of: reduceMotion) { _, reduced in
                if reduced { isLooping = false }
            }
    }

    private func replay() {
        isPlaying = true
        replayID += 1
    }
}

#Preview {
    NavigationStack { FloatingSplashDemoView() }
}
