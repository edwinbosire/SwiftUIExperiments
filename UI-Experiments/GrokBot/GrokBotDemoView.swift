import SwiftUI

/// The welcome composition from main-2.mp4, with individually tappable bots.
struct GrokBotDemoView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showsReactions = false
    @State private var replay = 0

    var body: some View {
        ZStack {
            GrokBotPaper.color.ignoresSafeArea()
            GrokBotWelcomeStage()
                .id(replay)
                .ignoresSafeArea()
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button {
                showsReactions = true
            } label: {
                Text("Sign in")
                    .font(.body.weight(.medium))
                    .padding(.vertical, 10)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Color(white: 0.095), in: Capsule())
                    .shadow(color: .black.opacity(0.13), radius: 18, y: 9)
            }
            .buttonStyle(GrokPressStyle())
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 28)
            .padding(.bottom, 5)
            .accessibilityHint("Opens the mascot reactions demo")
            .accessibilityIdentifier("grok-reactions")
        }
        .overlay(alignment: .topLeading) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.gray.opacity(0.6))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.leading, 12)
            .accessibilityLabel("Back to experiments")
            .accessibilityIdentifier("close-grok-demo")
        }
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.light)
        .sheet(isPresented: $showsReactions) {
            GrokBotReactionsView {
                showsReactions = false
                replay += 1
            }
        }
    }
}

private enum GrokBotPaper {
    static let color = Color(white: 0.987)
}

private struct GrokBotWelcomeStage: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize = 32
    @ScaledMetric(relativeTo: .subheadline) private var subtitleSize = 14.5

    var body: some View {
        GeometryReader { geometry in
            let width = min(geometry.size.width, 1000)
            let height = max(geometry.size.height, 540)
            ScrollView {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(spacing: 24) {
                        introduction.padding(.horizontal, 28).padding(.top, 60)
                        bots(in: CGSize(width: width, height: 550))
                            .frame(height: 550)
                    }
                    .frame(width: width)
                    .frame(maxWidth: .infinity)
                } else {
                    ZStack {
                        bots(in: CGSize(width: width, height: height))
                        introduction
                            .frame(width: min(500, width * 0.76))
                            .position(x: width / 2, y: height * 0.497)
                            .allowsHitTesting(false)
                    }
                    .frame(width: width, height: height)
                    .frame(maxWidth: .infinity)
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
            .accessibilityIdentifier("grok-welcome-scroll")
        }
    }

    private var introduction: some View {
        VStack(spacing: 14) {
            Text("Grok Bot")
                .font(.system(size: titleSize, weight: .medium))
                .foregroundStyle(.black)
                .accessibilityAddTraits(.isHeader)
            Text("Your team of always-on agents\nthat finish the work.")
                .font(.system(size: subtitleSize))
                .foregroundStyle(Color(white: 0.55))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func bots(in size: CGSize) -> some View {
        GrokAnimationTimeline { time in
            ZStack {
                ForEach(GrokBot.allCases) { bot in
                    GrokFloatingBot(bot: bot, time: time, scale: min(size.width / 390, 1.4))
                        .position(bot.position(at: time, in: size))
                }
            }
        }
        .frame(width: size.width, height: size.height)
        .clipped()
    }
}


private struct GrokFloatingBot: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var reactedAt: Double?
    @State private var tapCount = 0
    let bot: GrokBot
    let time: Double
    let scale: Double

    private var reaction: GrokReaction {
        guard let reactedAt, time - reactedAt < 2.2 else { return .automatic }
        let reactions: [GrokReaction] = [.happy, .surprised, .curious, .blink]
        return reactions[(tapCount - 1) % reactions.count]
    }

    var body: some View {
        let reactionTime = reaction == .automatic ? time : time - (reactedAt ?? 0)
        let bounce = reaction == .automatic || reduceMotion ? 0 : sin(min(reactionTime, 0.6) / 0.6 * .pi) * 7

        Button {
            tapCount += 1
            reactedAt = time
        } label: {
            GrokBotArtwork(bot: bot, reaction: reaction, time: reactionTime)
                .frame(width: bot.size.width * scale, height: bot.size.height * scale)
                .rotationEffect(.degrees(reduceMotion ? 0 : bot.rotation(at: time)))
                .offset(y: -bounce)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(GrokPressStyle())
        .accessibilityLabel(bot.name)
        .accessibilityValue(reaction.rawValue)
        .accessibilityHint("Tap to change its expression")
        .accessibilityIdentifier("grok-bot-\(bot.rawValue)")
        .sensoryFeedback(.selection, trigger: tapCount)
    }
}

private struct GrokBotReactionsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var reaction: GrokReaction = .automatic
    @State private var replay = 0
    let onReplayWelcome: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("A little personality.")
                            .font(.system(.title, design: .rounded, weight: .semibold))
                        Text("Nine bots. Every expression. Tap one to give it a new reaction.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    GrokReactionPicker(selection: $reaction) { replay += 1 }

                    LazyVGrid(columns: dynamicTypeSize.isAccessibilitySize
                              ? [GridItem(.flexible())]
                              : [GridItem(.adaptive(minimum: 140), spacing: 14)], spacing: 14) {
                        ForEach(GrokBot.allCases) { bot in
                            GrokBotReactionCard(bot: bot, reaction: reaction)
                                .id(GrokCardIdentity(bot: bot, replay: replay))
                        }
                    }

                    Button(action: onReplayWelcome) {
                        Label("Replay welcome", systemImage: "arrow.counterclockwise")
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(Color(white: 0.93), in: Capsule())
                    }
                    .buttonStyle(GrokPressStyle())
                    .accessibilityIdentifier("grok-replay-welcome")
                }
                .padding(20)
                .frame(maxWidth: 960)
                .frame(maxWidth: .infinity)
            }
            .background(GrokBotPaper.color)
            .navigationTitle("Meet the bots")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Replay", systemImage: "arrow.counterclockwise") { replay += 1 }
                        .labelStyle(.iconOnly)
                        .accessibilityIdentifier("grok-replay-reactions")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .tint(.black)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.light)
    }
}

private struct GrokCardIdentity: Hashable {
    let bot: GrokBot
    let replay: Int
}

private struct GrokReactionPicker: View {
    @Binding var selection: GrokReaction
    let onSelect: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(GrokReaction.allCases) { reaction in
                    Button {
                        selection = reaction
                        onSelect()
                    } label: {
                        Label(reaction.rawValue, systemImage: reaction.symbol)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 15)
                            .padding(.vertical, 12)
                            .foregroundStyle(selection == reaction ? .white : .black)
                            .background(selection == reaction ? .black : Color(white: 0.93), in: Capsule())
                    }
                    .buttonStyle(GrokPressStyle())
                    .accessibilityAddTraits(selection == reaction ? .isSelected : [])
                    .accessibilityIdentifier("grok-reaction-\(reaction.rawValue)")
                }
            }
        }
    }
}

private struct GrokBotReactionCard: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var localReaction: GrokReaction?
    let bot: GrokBot
    let reaction: GrokReaction

    private var activeReaction: GrokReaction { localReaction ?? reaction }

    var body: some View {
        Button {
            let choices = GrokReaction.allCases
            let index = choices.firstIndex(of: activeReaction) ?? 0
            localReaction = choices[(index + 1) % choices.count]
        } label: {
            VStack(spacing: 12) {
                GrokAnimationTimeline { time in
                    GrokBotArtwork(bot: bot, reaction: activeReaction, time: time)
                        .frame(width: bot.size.width * 1.12, height: bot.size.height * 1.12)
                        .rotationEffect(.degrees(reduceMotion ? 0 : bot.rotation(at: time)))
                        .offset(y: reduceMotion ? 0 : sin(time * 1.6 + bot.reactionOffset) * 3)
                        .frame(maxWidth: .infinity)
                        .frame(height: 115)
                }
                VStack(spacing: 4) {
                    Text(bot.name)
                        .font(.subheadline.weight(.medium))
                    Text(activeReaction == .automatic ? "Looking around" : activeReaction.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)
            }
            .foregroundStyle(.black)
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(.white, in: RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(.black.opacity(0.055), lineWidth: 1))
        }
        .buttonStyle(GrokPressStyle())
        .accessibilityLabel(bot.name)
        .accessibilityValue(activeReaction.rawValue)
        .accessibilityHint("Changes this bot's reaction")
        .accessibilityIdentifier("grok-card-\(bot.rawValue)")
        .onChange(of: reaction) { localReaction = nil }
    }
}

private struct GrokPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

#Preview("Grok Bot welcome") {
    NavigationStack {
        GrokBotDemoView()
    }
}

#Preview("All nine mascots") {
    GrokBotReactionsView(onReplayWelcome: {})
}
