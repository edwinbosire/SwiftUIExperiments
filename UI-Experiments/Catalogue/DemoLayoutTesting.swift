#if DEBUG
import SwiftUI
import UIKit

/// Launch-only hooks let UI tests exercise real feature views in resizable windows.
enum DemoLayoutTesting {
    static func argument(_ name: String) -> String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: name), arguments.indices.contains(index + 1) else { return nil }
        return arguments[index + 1]
    }

    static func selectedExperiment(in experiments: [CatalogueExperiment]) -> CatalogueExperiment? {
        guard let id = argument("-demo-test-feature") else { return nil }
        return experiments.first { $0.id == id }
    }

    static var viewport: CGSize? {
        guard let width = argument("-demo-test-width").flatMap(Double.init),
              let height = argument("-demo-test-height").flatMap(Double.init),
              width.isFinite, height.isFinite, width > 0, height > 0 else { return nil }
        return CGSize(width: width, height: height)
    }
}

struct DemoLayoutTestViewport: ViewModifier {
    @ViewBuilder func body(content: Content) -> some View {
        if let size = DemoLayoutTesting.viewport {
            ConstrainedDemoHost(content: content, size: size)
                .accessibilityIdentifier("demo-test-viewport")
        } else {
            content
        }
    }
}

// A child hosting controller gives NavigationStack and presentations real bounds,
// rather than clipping a full-screen navigation controller with a SwiftUI frame.
private struct ConstrainedDemoHost<Content: View>: UIViewControllerRepresentable {
    let content: Content
    let size: CGSize

    func makeUIViewController(context: Context) -> DemoViewportController<Content> {
        DemoViewportController(content: content, size: size)
    }

    func updateUIViewController(_ controller: DemoViewportController<Content>, context: Context) {
        controller.host.rootView = content
    }
}

private final class DemoViewportController<Content: View>: UIViewController {
    let host: UIHostingController<Content>
    let viewportSize: CGSize

    init(content: Content, size: CGSize) {
        host = UIHostingController(rootView: content)
        viewportSize = size
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("Use init(content:size:)") }

    override func viewDidLoad() {
        super.viewDidLoad()
        addChild(host)
        view.addSubview(host.view)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        let width = host.view.widthAnchor.constraint(equalToConstant: viewportSize.width)
        let height = host.view.heightAnchor.constraint(equalToConstant: viewportSize.height)
        width.priority = .defaultHigh
        height.priority = .defaultHigh
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            host.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            host.view.widthAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.widthAnchor),
            host.view.heightAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.heightAnchor),
            width, height
        ])
        host.didMove(toParent: self)
    }
}
#endif
