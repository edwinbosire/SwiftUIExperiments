import Observation
import RiveRuntime
import SwiftUI

/// Owns the runtime and the exact instance bound to its artboard and state machine.
@MainActor @Observable
final class TravelRiveController {
    private(set) var viewModel: RiveViewModel?
    private(set) var errorDescription: String?
    @ObservationIgnored private(set) var bindingInstance: RiveDataBindingViewModel.Instance?

    func load() {
        guard viewModel == nil else { return }
        do {
            let model = try RiveModel(fileName: "TravelOnboarding", loadCdn: false)
            // Validate names before passing the model to the runtime's view wrapper.
            try model.setArtboard("Travel Onboarding")
            try model.setStateMachine("Onboarding")
            let player = RiveViewModel(model, stateMachineName: "Onboarding", autoPlay: false,
                                       artboardName: "Travel Onboarding")
            model.enableAutoBind { [weak self] instance in
                self?.bindingInstance = instance
            }
            guard let instance = bindingInstance,
                  instance.numberProperty(fromPath: "progress") != nil,
                  instance.numberProperty(fromPath: "travelStyle") != nil,
                  instance.numberProperty(fromPath: "motionDuration") != nil,
                  instance.stringProperty(fromPath: "travelerName") != nil,
                  instance.colorProperty(fromPath: "accentColor") != nil,
                  instance.booleanProperty(fromPath: "isComplete") != nil,
                  instance.booleanProperty(fromPath: "reduceMotion") != nil else {
                throw AssetError.invalidBindings
            }
            viewModel = player
            errorDescription = nil
        } catch {
            bindingInstance = nil
            errorDescription = "The travel animation couldn’t load. You can still set up your journey."
        }
    }

    func update(from state: TravelOnboardingState, reduceMotion: Bool) {
        guard let instance = bindingInstance else { return }
        instance.numberProperty(fromPath: "motionDuration")?.value = reduceMotion ? 0 : 0.35
        instance.numberProperty(fromPath: "progress")?.value = state.progress
        instance.numberProperty(fromPath: "travelStyle")?.value = state.style.riveValue
        instance.stringProperty(fromPath: "travelerName")?.value = state.passName
        instance.colorProperty(fromPath: "accentColor")?.value = UIColor(state.style.accent)
        instance.booleanProperty(fromPath: "isComplete")?.value = state.isComplete
        instance.booleanProperty(fromPath: "reduceMotion")?.value = reduceMotion
        // Data changes must also render when the display link is paused.
        viewModel?.riveView?.advance(delta: 0)
    }

    func setPlayback(active: Bool, reduceMotion: Bool) {
        guard let viewModel else { return }
        if active && !reduceMotion {
            viewModel.play()
        } else {
            viewModel.pause()
            viewModel.riveView?.advance(delta: 0)
        }
    }

    private enum AssetError: Error { case invalidBindings }
}
