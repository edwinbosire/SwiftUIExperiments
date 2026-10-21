import SwiftUI

struct DynamicLayoutDemoView: View {
    @State private var components = LayoutComponent.samples
    @State private var isDragging = false
    @State private var nextComponentNumber = 9
    @State private var newlyAddedID: String?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("A place for every shape.")
                            .font(.title2.bold())
                        Text("Touch and hold a rectangle, then drag. The layout rearranges around it as you move.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if components.isEmpty {
                        ContentUnavailableView("No rectangles", systemImage: "rectangle.3.group",
                                               description: Text("Tap + to add a rectangle."))
                            .accessibilityIdentifier("empty-layout")
                            .transition(.opacity)
                    }

                    ReorderableFlow(items: $components, width: { $0.width }, onDraggingChanged: { isDragging = $0 }, onDelete: deleteComponent) { component in
                        LayoutRectangle(component: component)
                    }

                    Label("Flexible rectangles share the space left in each row, while keeping their minimum width.", systemImage: "arrow.left.and.right")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .scrollDisabled(isDragging)
            .navigationTitle("Dynamic layout")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: newlyAddedID) { _, id in
                if let id {
                    withAnimation(reduceMotion ? nil : .snappy(duration: 0.3)) {
                        scrollProxy.scrollTo(id, anchor: .bottom)
                    }
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Reset", systemImage: "arrow.counterclockwise") {
                        withAnimation(reduceMotion ? nil : .snappy) {
                            newlyAddedID = nil
                            nextComponentNumber = 9
                            components = LayoutComponent.samples
                        }
                    }
                    .accessibilityIdentifier("reset-layout")

                    Button("Add rectangle", systemImage: "plus", action: addComponent)
                        .accessibilityIdentifier("add-layout-component")
                }
            }
        }
    }

    private func addComponent() {
        let component = LayoutComponent.random(id: String(nextComponentNumber))
        nextComponentNumber += 1
        withAnimation(reduceMotion ? nil : .snappy(duration: 0.3)) {
            components.append(component)
            newlyAddedID = component.id
        }
    }

    private func deleteComponent(_ component: LayoutComponent) {
        withAnimation(reduceMotion ? nil : .snappy(duration: 0.3)) {
            components.removeAll { $0.id == component.id }
        }
    }
}

private struct LayoutRectangle: View {
    let component: LayoutComponent

    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(component.color.gradient)
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(component.id)
                        .font(.title2.bold())
                    Text(component.width.isFlexible
                         ? "Min \(Int(component.width.minimumWidth)) pt"
                         : "\(Int(component.width.minimumWidth)) × \(Int(component.height))")
                        .font(.caption.monospacedDigit())
                    if component.width.isFlexible {
                        Label("Flexible", systemImage: "arrow.left.and.right")
                            .font(.caption2.bold())
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(.black.opacity(0.55), in: Capsule())
                    }
                }
                .foregroundStyle(.white)
                .padding(12)
            }
            .frame(minWidth: component.width.minimumWidth,
                   maxWidth: component.width.isFlexible ? .infinity : component.width.minimumWidth)
            .frame(height: component.height)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Rectangle \(component.id), \(component.width.isFlexible ? "flexible, minimum width" : "fixed width") \(Int(component.width.minimumWidth)) points")
    }
}

private struct LayoutComponent: Identifiable {
    let id: String
    let color: Color
    let width: FlowItemWidth
    let height: CGFloat

    static func random(id: String) -> LayoutComponent {
        let colors: [Color] = [.indigo, .teal, .orange, .pink, .blue, .purple, .mint, .red]
        let width = CGFloat(Int.random(in: 6...10) * 20)
        return LayoutComponent(
            id: id,
            color: colors.randomElement() ?? .blue,
            width: Bool.random() ? .fixed(width) : .flexible(minimum: width),
            height: CGFloat(Int.random(in: 5...8) * 20)
        )
    }

    static let samples: [LayoutComponent] = [
        .init(id: "A", color: .indigo, width: .fixed(150), height: 100),
        .init(id: "B", color: .teal, width: .flexible(minimum: 110), height: 150),
        .init(id: "C", color: .orange, width: .flexible(minimum: 170), height: 110),
        .init(id: "D", color: .pink, width: .fixed(120), height: 120),
        .init(id: "E", color: .blue, width: .fixed(100), height: 90),
        .init(id: "F", color: .purple, width: .flexible(minimum: 180), height: 130),
        .init(id: "G", color: .mint, width: .flexible(minimum: 130), height: 110),
        .init(id: "H", color: .red, width: .flexible(minimum: 140), height: 110)
    ]
}

#Preview {
    NavigationStack {
        DynamicLayoutDemoView()
    }
}
