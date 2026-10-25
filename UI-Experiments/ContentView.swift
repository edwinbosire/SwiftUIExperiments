import SwiftUI

struct ContentView: View {
    var body: some View {
        let experiments = [
            CatalogueExperiment(id: "rive-onboarding-demo", title: "Rive Onboarding",
                                detail: "A little journey, brought to life.", category: .motion, artwork: .journey) {
                RiveOnboardingDemoView()
            },
            CatalogueExperiment(id: "floating-splash-demo", title: "Floating splash",
                                detail: "A little room to play. Again and again.", category: .motion, artwork: .splash) {
                FloatingSplashDemoView()
            },
            CatalogueExperiment(id: "x-stock-demo", title: "X stock graph",
                                detail: "Follow the curve. Feel every change.", category: .controls, artwork: .graph) {
                XStockGraphDemoView()
            },
            CatalogueExperiment(id: "grok-bot-demo", title: "Grok Bot mascots",
                                detail: "Little characters. Lots of personality.", category: .motion, artwork: .mascots) {
                GrokBotDemoView()
            },
            CatalogueExperiment(id: "duo-owl-demo", title: "Duo owl",
                                detail: "A familiar face with a playful side.", category: .motion, artwork: .owl) {
                DuoOwlDemoView()
            },
            CatalogueExperiment(id: "ultracode-demo", title: "Ultracode",
                                detail: "Turn the effort up to eleven.", category: .motion, artwork: .guitar) {
                UltracodeDemoView()
            },
            CatalogueExperiment(id: "dynamic-layout-demo", title: "Dynamic layout",
                                detail: "A little room to move things around.", category: .layouts, artwork: .layout) {
                DynamicLayoutDemoView()
            },
            CatalogueExperiment(id: "animated-checkbox-demo", title: "Animated checkbox",
                                detail: "Small wins, with a satisfying finish.", category: .controls, artwork: .checkbox) {
                AnimatedCheckboxDemoView()
            },
            CatalogueExperiment(id: "quiz-demo", title: "Quiz Page",
                                detail: "Good questions. Thoughtful interactions.", category: .layouts, artwork: .quiz) {
                StickyHeaderQuestionView()
            },
            CatalogueExperiment(id: "highlighter-demo", title: "HTML highlighter",
                                detail: "Keep the words that stay with you.", category: .controls, artwork: .highlighter) {
                HighlightSampleView()
            },
            CatalogueExperiment(id: "intensity-picker-demo", title: "Intensity picker",
                                detail: "Find just the right amount.", category: .controls, artwork: .sliders) {
                IntensityPickerDemoView()
            },
            CatalogueExperiment(id: "cover-flow-demo", title: "Cover Flow",
                                detail: "A fresh perspective on your next read.", category: .layouts, artwork: .books) {
                CoverFlowDemoView()
            }
        ]
        #if DEBUG
        if let experiment = DemoLayoutTesting.selectedExperiment(in: experiments) {
            NavigationStack { experiment.destination() }
        } else {
            ExperimentCatalogueView(experiments: experiments)
        }
        #else
        ExperimentCatalogueView(experiments: experiments)
        #endif
    }
}

#Preview {
    ContentView()
}
