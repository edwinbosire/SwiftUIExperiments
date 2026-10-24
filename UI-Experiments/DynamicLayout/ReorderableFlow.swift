import SwiftUI

/// A wrapping layout whose placeholder and surrounding items move during a drag.
struct ReorderableFlow<Item: Identifiable, Content: View>: View {
    @Binding var items: [Item]
    var spacing: CGFloat = 12
    var width: ((Item) -> FlowItemWidth)? = nil
    var onDraggingChanged: (Bool) -> Void = { _ in }
    var onDelete: ((Item) -> Void)? = nil
    @ViewBuilder var content: (Item) -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var coordinateSpace
    @GestureState private var drag: FlowDrag<Item.ID>?
    @State private var session: FlowDragSession<Item.ID>?
    @State private var frames: [Item.ID: CGRect] = [:]
    @State private var layoutWidth: CGFloat = 0

    var body: some View {
        FlowLayout(spacing: spacing) {
            ForEach(items) { item in
                tile(item)
            }
        }
        .animation(reduceMotion ? nil : .snappy(duration: 0.25), value: items.map(\.id))
        .coordinateSpace(.named(coordinateSpace))
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { layoutWidth = $0 }
        .onPreferenceChange(FlowFrames<Item.ID>.self) { frames = $0 }
        .overlay(alignment: .topLeading) {
            // Keep the lifted view outside the animated layout. Its origin is captured
            // once, so moving its placeholder cannot move it away from the finger.
            if let session, let drag, let item = items.first(where: { $0.id == session.id }) {
                content(item)
                    .frame(width: session.origin.width, height: session.origin.height)
                    .shadow(color: .black.opacity(0.2), radius: 14, y: 8)
                    .scaleEffect(reduceMotion ? 1 : 1.04)
                    .offset(x: session.origin.minX + drag.translation.width,
                            y: session.origin.minY + drag.translation.height)
                    .transaction { $0.animation = nil }
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .simultaneousGesture(reorderGesture)
        .onChange(of: drag?.id) { _, id in
            onDraggingChanged(id != nil)
            if id == nil, let session {
                // GestureState also resets on interruption, when onEnded isn't called.
                let order = session.originalOrder
                items.sort { (order.firstIndex(of: $0.id) ?? order.count) < (order.firstIndex(of: $1.id) ?? order.count) }
                self.session = nil
            }
        }
        .onDisappear {
            session = nil
            onDraggingChanged(false)
        }
    }

    private func tile(_ item: Item) -> some View {
        content(item)
            .opacity(drag?.id == item.id ? 0.18 : 1)
            .background {
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: FlowFrames<Item.ID>.self,
                        value: [item.id: geometry.frame(in: .named(coordinateSpace))]
                    )
                }
            }
            .layoutValue(key: FlowItemWidthKey.self, value: width?(item))
            .contentShape(.rect)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("flow-item-\(item.id)")
            .accessibilityValue("Position \(position(of: item) + 1) of \(items.count)")
            .accessibilityActions {
                if position(of: item) > 0 {
                    Button("Move earlier") { move(item, to: position(of: item) - 1) }
                }
                if position(of: item) < items.count - 1 {
                    Button("Move later") { move(item, to: position(of: item) + 1) }
                }
            }
            .overlay(alignment: .topTrailing) {
                if let onDelete {
                    Button {
                        onDelete(item)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(.black.opacity(0.55), in: Circle())
                            .frame(width: 44, height: 44)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Delete rectangle \(String(describing: item.id))")
                    .accessibilityIdentifier("delete-item-\(item.id)")
                    .disabled(drag != nil)
                }
            }
            .transition(reduceMotion ? .opacity : .scale(scale: 0.85).combined(with: .opacity))
            .id(item.id)
    }

    private var reorderGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.25)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .named(coordinateSpace)))
            .updating($drag) { value, state, _ in
                if case .second(true, let movement?) = value,
                   let item = draggedItem(at: movement.startLocation) {
                    state = FlowDrag(id: item.id, translation: movement.translation)
                }
            }
            .onChanged { value in
                guard case .second(true, let movement?) = value,
                      let item = draggedItem(at: movement.startLocation) else { return }
                if session == nil, let origin = frames[item.id] {
                    session = FlowDragSession(id: item.id, origin: origin, originalOrder: items.map(\.id))
                }
                updateOrder(for: item, movement: movement)
            }
            .onEnded { _ in
                // The binding already contains the previewed order. Removing the lifted
                // copy reveals the placeholder at precisely its final destination.
                session = nil
            }
    }

    private func draggedItem(at startLocation: CGPoint) -> Item? {
        if let session { return items.first { $0.id == session.id } }
        return items.first { frames[$0.id]?.contains(startLocation) == true }
    }

    private func updateOrder(for item: Item, movement: DragGesture.Value) {
        guard let session, layoutWidth > 0,
              abs(movement.translation.width) + abs(movement.translation.height) > 4,
              items.allSatisfy({ frames[$0.id] != nil }),
              let source = items.firstIndex(where: { $0.id == item.id }) else { return }

        let point = movement.location
        if let last = session.lastReorderLocation,
           hypot(point.x - last.x, point.y - last.y) < 12 { return }

        // Use destination geometry, not intermediate animated frames, for hit testing.
        let arrangement = FlowArrangement(
            sizes: items.compactMap { item in
                frames[item.id].map { frame in
                    CGSize(width: width?(item).minimumWidth ?? frame.width, height: frame.height)
                }
            },
            width: layoutWidth,
            spacing: spacing,
            flexibleIndices: Set(items.indices.filter { width?(items[$0]).isFlexible == true })
        )
        guard !arrangement.frames[source].insetBy(dx: -spacing / 2, dy: -spacing / 2).contains(point) else { return }
        let boundary = FlowArrangement.insertionIndex(at: point, frames: arrangement.frames)
        let destination = boundary > source ? boundary - 1 : boundary
        guard source != destination else { return }
        self.session?.lastReorderLocation = point
        move(item, to: destination)
    }

    private func position(of item: Item) -> Int {
        items.firstIndex { $0.id == item.id } ?? 0
    }

    private func move(_ item: Item, to destination: Int) {
        guard let source = items.firstIndex(where: { $0.id == item.id }), source != destination else { return }
        let moved = items.remove(at: source)
        items.insert(moved, at: min(max(destination, 0), items.count))
    }
}

private struct FlowDrag<ID: Hashable> {
    let id: ID
    let translation: CGSize
}

private struct FlowDragSession<ID: Hashable> {
    let id: ID
    let origin: CGRect
    let originalOrder: [ID]
    var lastReorderLocation: CGPoint?
}

private struct FlowFrames<ID: Hashable>: PreferenceKey {
    static var defaultValue: [ID: CGRect] { [:] }
    static func reduce(value: inout [ID: CGRect], nextValue: () -> [ID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}
