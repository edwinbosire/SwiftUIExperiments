import SwiftUI

struct RiveOnboardingDemoView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AppStorage("riveOnboarding.travelerName") private var savedName = ""
    @AppStorage("riveOnboarding.travelStyle") private var savedStyle = OnboardingTravelStyle.mountains.rawValue
    @AppStorage("riveOnboarding.completed") private var hasCompletedOnboarding = false
    @State private var onboarding = TravelOnboardingState()
    @State private var animation = TravelRiveController()
    @State private var isVisible = false
    @State private var didLoadPreferences = false
    @FocusState private var nameIsFocused: Bool

    private let ink = Color(red: 0.12, green: 0.27, blue: 0.22)
    private let paper = Color(red: 0.97, green: 0.96, blue: 0.93)
    private let muted = Color(red: 0.43, green: 0.48, blue: 0.42)

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 28)
                    .padding(.top, 12)
                ScrollViewReader { scroll in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            hero
                                .frame(height: heroHeight(in: geometry.size))
                                .padding(.top, 8)
                                .padding(.bottom, 20)
                                .id("onboarding-top")
                            story
                            stepContent
                                .padding(.top, 24)
                        }
                        .padding(.horizontal, 28)
                        .padding(.bottom, 24)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: onboarding.step) { scroll.scrollTo("onboarding-top", anchor: .top) }
                    .onChange(of: onboarding.isComplete) { scroll.scrollTo("onboarding-top", anchor: .top) }
                }
                footer
                    .padding(.horizontal, 28)
                    .padding(.top, 12)
                    .padding(.bottom, 14)
            }
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        .background(paper.ignoresSafeArea())
        .foregroundStyle(ink)
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.light)
        .onAppear {
            onboarding.replay()
            isVisible = true
            if !didLoadPreferences {
                onboarding.travelerName = savedName
                onboarding.style = OnboardingTravelStyle(rawValue: savedStyle) ?? .mountains
                didLoadPreferences = true
            }
            animation.load()
            synchronizeAnimation()
        }
        .onDisappear {
            isVisible = false
            animation.setPlayback(active: false, reduceMotion: reduceMotion)
        }
        .onChange(of: scenePhase) { synchronizeAnimation() }
        .onChange(of: reduceMotion) { synchronizeAnimation() }
        .onChange(of: onboarding.step) {
            nameIsFocused = false
            synchronizeAnimation()
        }
        .onChange(of: onboarding.style) {
            savedStyle = onboarding.style.rawValue
            synchronizeAnimation()
        }
        .onChange(of: onboarding.travelerName) {
            savedName = onboarding.travelerName
            synchronizeAnimation()
        }
        .onChange(of: onboarding.isComplete) {
            if onboarding.isComplete { hasCompletedOnboarding = true }
            synchronizeAnimation()
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Button {
                nameIsFocused = false
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 44, height: 44)
                    .background(ink.opacity(0.055), in: Circle())
            }
            .accessibilityLabel("Close Rive Onboarding")
            .accessibilityIdentifier("close-rive-onboarding")
            Spacer()
            HStack(spacing: 5) {
                Image(systemName: "safari")
                    .font(.system(size: 19, weight: .light))
                Text("roam")
                    .font(.system(size: 25, weight: .semibold, design: .serif))
            }
            .accessibilityElement(children: .combine)
            Spacer()
            if !onboarding.isComplete && onboarding.step != .traveler {
                Button("Skip") { changeStep { onboarding.skipIntroduction() } }
                    .font(.subheadline)
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityIdentifier("rive-onboarding-skip")
            } else {
                Color.clear.frame(width: 44, height: 44)
                    .accessibilityHidden(true)
            }
        }
        .buttonStyle(.plain)
    }

    private var hero: some View {
        Group {
            if let player = animation.viewModel {
                player.view()
                    .onAppear { synchronizeAnimation() }
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            } else if let message = animation.errorDescription {
                VStack(spacing: 12) {
                    Image(systemName: "suitcase.rolling")
                        .font(.system(size: 76, weight: .ultraLight))
                    Text(message).font(.callout).multilineTextAlignment(.center)
                    Button("Reload animation") {
                        animation.load()
                        synchronizeAnimation()
                    }
                }
                .foregroundStyle(muted)
            } else {
                ProgressView().tint(ink)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("rive-onboarding-artwork")
    }

    private var story: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(eyebrow)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .tracking(2.2)
                .foregroundStyle(muted)
            Text(title)
                .font(.system(.largeTitle, design: .serif, weight: .regular))
                .lineSpacing(0)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("rive-onboarding-title")
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(muted)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder private var stepContent: some View {
        if onboarding.isComplete {
            HStack(spacing: 12) {
                Image(systemName: onboarding.style.symbol)
                    .font(.title2)
                    .foregroundStyle(onboarding.style.accent)
                VStack(alignment: .leading, spacing: 5) {
                    Text(onboarding.style.title).font(.subheadline.weight(.semibold))
                    Text("Your travel style is saved.").font(.caption).foregroundStyle(muted)
                }
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(onboarding.style.accent)
            }
            .padding(18)
            .background(.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 16))
        } else {
            switch onboarding.step {
            case .discover:
                HStack(spacing: 8) {
                    Image(systemName: "location.north.line")
                    Text("Less planning. More living.")
                }
                .font(.footnote)
                .foregroundStyle(muted)
            case .travelStyle:
                VStack(spacing: 9) {
                    ForEach(OnboardingTravelStyle.allCases) { style in
                        styleButton(style)
                    }
                }
            case .traveler:
                VStack(alignment: .leading, spacing: 9) {
                    Text("What should we call you?")
                        .font(.subheadline.weight(.medium))
                    TextField("Your first name (optional)", text: $onboarding.travelerName)
                        .textContentType(.givenName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .focused($nameIsFocused)
                        .onSubmit { nameIsFocused = false }
                        .padding(16)
                        .background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 14))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14).stroke(ink.opacity(0.15), lineWidth: 1)
                        }
                        .accessibilityIdentifier("rive-onboarding-name")
                    Text("Your name, your very own boarding pass.")
                        .font(.caption)
                        .foregroundStyle(muted)
                }
            }
        }
    }

    private func styleButton(_ style: OnboardingTravelStyle) -> some View {
        let selected = onboarding.style == style
        return Button {
            onboarding.style = style
        } label: {
            HStack(spacing: 13) {
                Image(systemName: style.symbol)
                    .font(.system(size: 21, weight: .regular))
                    .frame(width: 28)
                    .foregroundStyle(style.accent)
                VStack(alignment: .leading, spacing: 4) {
                    Text(style.title).font(.subheadline.weight(.medium))
                    Text(style.subtitle).font(.caption).foregroundStyle(muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 2)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(selected ? style.accent : ink.opacity(0.2))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(selected ? style.accent.opacity(0.07) : .white.opacity(0.45),
                        in: RoundedRectangle(cornerRadius: 15))
            .overlay {
                RoundedRectangle(cornerRadius: 15)
                    .stroke(selected ? style.accent.opacity(0.6) : ink.opacity(0.1), lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 15))
        }
        .buttonStyle(.plain)
        .accessibilityValue(selected ? "Selected" : "Not selected")
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("rive-onboarding-style-\(style.rawValue)")
    }

    private var footer: some View {
        VStack(spacing: 18) {
            HStack(spacing: 6) {
                ForEach(TravelOnboardingState.Step.allCases, id: \.rawValue) { step in
                    Capsule()
                        .fill(onboarding.isComplete || onboarding.step.rawValue >= step.rawValue ? ink : ink.opacity(0.12))
                        .frame(width: onboarding.step == step && !onboarding.isComplete ? 27 : 7, height: 5)
                }
                Spacer()
                Text(onboarding.isComplete ? "READY TO ROAM" : String(format: "%02d / 03", onboarding.step.rawValue + 1))
                    .font(.system(size: 10, design: .monospaced))
                    .tracking(1.5)
                    .foregroundStyle(muted)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(onboarding.isComplete ? "Onboarding complete" : "Step \(onboarding.step.rawValue + 1) of 3")

            Button {
                nameIsFocused = false
                if onboarding.isComplete { dismiss() }
                else { changeStep { onboarding.next() } }
            } label: {
                HStack {
                    Spacer()
                    Text(primaryButtonTitle).font(.body.weight(.medium))
                    Spacer()
                    Image(systemName: "arrow.right").font(.system(size: 17))
                }
                .padding(.horizontal, 23)
                .padding(.vertical, 18)
                .background(ink, in: RoundedRectangle(cornerRadius: 18))
                .foregroundStyle(paper)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("rive-onboarding-next")

            Button {
                if onboarding.isComplete { changeStep { onboarding.replay() } }
                else if onboarding.step != .discover { changeStep { onboarding.back() } }
            } label: {
                Text(onboarding.isComplete ? "Replay the journey" : onboarding.step == .discover ? "Made for the way you wander." : "Back")
                    .font(.caption)
                    .foregroundStyle(muted)
                    .frame(maxWidth: .infinity, minHeight: 26)
            }
            .disabled(!onboarding.isComplete && onboarding.step == .discover)
            .accessibilityIdentifier("rive-onboarding-back")
        }
    }

    private var eyebrow: String {
        if onboarding.isComplete { return "THE WORLD IS WAITING" }
        switch onboarding.step {
        case .discover: return "A LITTLE CURIOSITY GOES A LONG WAY"
        case .travelStyle: return "FIND YOUR OWN WAY"
        case .traveler: return "ONE LAST THING, EXPLORER"
        }
    }

    private var title: String {
        if onboarding.isComplete { return onboarding.completionTitle }
        switch onboarding.step {
        case .discover: return "A little further.\nA little freer."
        case .travelStyle: return "What’s your kind\nof getaway?"
        case .traveler: return "Every great trip\nstarts with you."
        }
    }

    private var subtitle: String {
        if onboarding.isComplete { return "A new perspective is closer than you think.\nLet’s make a little room for adventure." }
        switch onboarding.step {
        case .discover: return "Find the places that make you feel something.\nWe’ll help you take the scenic route."
        case .travelStyle: return "Follow your first instinct. You can always\nchange direction later."
        case .traveler: return "We’ve packed a little inspiration for you.\nAll that’s missing is your name."
        }
    }

    private var primaryButtonTitle: String {
        if onboarding.isComplete { return "Start exploring" }
        switch onboarding.step {
        case .discover: return "Find my adventure"
        case .travelStyle: return "That’s my kind of trip"
        case .traveler: return "Let’s go"
        }
    }

    private func heroHeight(in size: CGSize) -> CGFloat {
        if dynamicTypeSize.isAccessibilitySize { return 220 }
        if onboarding.isComplete { return min(280, size.height * 0.34) }
        if onboarding.step == .travelStyle { return min(150, size.height * 0.20) }
        if onboarding.step == .traveler { return min(235, size.height * 0.28) }
        return min(340, max(225, size.height * 0.41))
    }

    private func changeStep(_ change: () -> Void) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.24), change)
    }

    private func synchronizeAnimation() {
        animation.update(from: onboarding, reduceMotion: reduceMotion)
        animation.setPlayback(active: isVisible && scenePhase == .active, reduceMotion: reduceMotion)
    }
}

#Preview {
    NavigationStack { RiveOnboardingDemoView() }
}
