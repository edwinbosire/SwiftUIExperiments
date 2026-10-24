import Observation
import SwiftUI

enum OnboardingTravelStyle: String, CaseIterable, Identifiable {
    case mountains, coast, city

    var id: String { rawValue }
    var title: String {
        switch self {
        case .mountains: "Into the mountains"
        case .coast: "Along the coast"
        case .city: "Around the city"
        }
    }
    var subtitle: String {
        switch self {
        case .mountains: "Fresh air. Higher perspectives."
        case .coast: "Salt in the air. Time to slow down."
        case .city: "New streets. A thousand little stories."
        }
    }
    var symbol: String {
        switch self {
        case .mountains: "mountain.2"
        case .coast: "water.waves"
        case .city: "building.2"
        }
    }
    var riveValue: Float {
        switch self {
        case .mountains: 0
        case .coast: 50
        case .city: 100
        }
    }
    var accent: Color {
        switch self {
        case .mountains: Color(red: 0.26, green: 0.43, blue: 0.33)
        case .coast: Color(red: 0.22, green: 0.48, blue: 0.51)
        case .city: Color(red: 0.65, green: 0.37, blue: 0.25)
        }
    }
}

@MainActor @Observable
final class TravelOnboardingState {
    enum Step: Int, CaseIterable {
        case discover, travelStyle, traveler
    }

    var step: Step = .discover
    var style: OnboardingTravelStyle = .mountains
    var travelerName = ""
    private(set) var isComplete = false

    var progress: Float { isComplete ? 100 : Float(step.rawValue + 1) / 3 * 100 }
    var displayName: String { travelerName.trimmingCharacters(in: .whitespacesAndNewlines) }
    var passName: String { displayName.isEmpty ? "WANDERER" : String(displayName.prefix(18)).uppercased() }
    var completionTitle: String { displayName.isEmpty ? "You’re going places." : "You’re going places,\n\(displayName)." }

    func next() {
        guard !isComplete else { return }
        if let next = Step(rawValue: step.rawValue + 1) {
            step = next
        } else {
            isComplete = true
        }
    }

    func back() {
        guard !isComplete, let previous = Step(rawValue: step.rawValue - 1) else { return }
        step = previous
    }

    func skipIntroduction() { step = .traveler }

    func replay() {
        isComplete = false
        step = .discover
    }
}
