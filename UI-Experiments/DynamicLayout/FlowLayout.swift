import SwiftUI

enum FlowItemWidth: Equatable {
    case fixed(CGFloat)
    case flexible(minimum: CGFloat)

    var minimumWidth: CGFloat {
        switch self {
        case .fixed(let width), .flexible(let width): max(0, width)
        }
    }

    var isFlexible: Bool {
        if case .flexible = self { return true }
        return false
    }
}

struct FlowItemWidthKey: LayoutValueKey {
    static let defaultValue: FlowItemWidth? = nil
}

/// Forms rows using minimum widths, then shares spare space between flexible items.
/// Each row is top-aligned and advances by its tallest item.
struct FlowLayout: Layout {
    var spacing: CGFloat = 12

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrangement(width: proposal.width, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangement(width: bounds.width, subviews: subviews)
        for (subview, frame) in zip(subviews, result.frames) {
            subview.place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                anchor: .topLeading,
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func arrangement(width: CGFloat?, subviews: Subviews) -> FlowArrangement {
        let limit = width.flatMap { $0.isFinite ? max(0, $0) : nil }
        let widths = subviews.map { $0[FlowItemWidthKey.self] }
        let flexible = Set(widths.indices.filter { widths[$0]?.isFlexible == true })
        var sizes = subviews.enumerated().map { index, subview in
            let ideal = subview.sizeThatFits(.unspecified)
            let width = widths[index]?.minimumWidth ?? min(ideal.width, limit ?? ideal.width)
            let measured = subview.sizeThatFits(ProposedViewSize(width: width, height: nil))
            return CGSize(width: width, height: measured.height)
        }
        let firstPass = FlowArrangement(sizes: sizes, width: limit, spacing: spacing, flexibleIndices: flexible)
        // Content such as text can change height when it receives its expanded width.
        for index in sizes.indices {
            sizes[index].height = subviews[index].sizeThatFits(
                ProposedViewSize(width: firstPass.frames[index].width, height: nil)
            ).height
        }
        return FlowArrangement(sizes: sizes, width: limit, spacing: spacing, flexibleIndices: flexible)
    }
}

/// Pure geometry shared by the layout and its tests.
struct FlowArrangement {
    let frames: [CGRect]
    let size: CGSize

    init(sizes: [CGSize], width: CGFloat?, spacing: CGFloat, flexibleIndices: Set<Int> = []) {
        // A declared minimum is a hard constraint, including in narrow containers.
        let availableWidth = width.map { max($0, sizes.map(\.width).max() ?? 0) }
        let limit = availableWidth ?? .greatestFiniteMagnitude
        let gap = max(0, spacing)
        var rows: [[Int]] = []
        var row: [Int] = []
        var rowWidth: CGFloat = 0
        for index in sizes.indices {
            let required = (row.isEmpty ? 0 : gap) + sizes[index].width
            if !row.isEmpty, rowWidth + required > limit {
                rows.append(row)
                row = []
                rowWidth = 0
            }
            rowWidth += (row.isEmpty ? 0 : gap) + sizes[index].width
            row.append(index)
        }
        if !row.isEmpty { rows.append(row) }

        var frames = Array(repeating: CGRect.zero, count: sizes.count)
        var y: CGFloat = 0
        var usedWidth: CGFloat = 0
        for row in rows {
            let minimumWidth = row.reduce(CGFloat.zero) { $0 + sizes[$1].width } + gap * CGFloat(row.count - 1)
            let flexibleCount = row.filter { flexibleIndices.contains($0) }.count
            let extra = flexibleCount > 0 ? max(0, (availableWidth ?? minimumWidth) - minimumWidth) / CGFloat(flexibleCount) : 0
            var x: CGFloat = 0
            var rowHeight: CGFloat = 0
            for index in row {
                let itemWidth = sizes[index].width + (flexibleIndices.contains(index) ? extra : 0)
                frames[index] = CGRect(x: x, y: y, width: itemWidth, height: sizes[index].height)
                usedWidth = max(usedWidth, x + itemWidth)
                rowHeight = max(rowHeight, sizes[index].height)
                x += itemWidth + gap
            }
            y += rowHeight + gap
        }
        self.frames = frames
        size = CGSize(width: availableWidth ?? usedWidth, height: rows.isEmpty ? 0 : y - gap)
    }

    /// Pick a row by its vertical extent, then an insertion boundary by item midpoints.
    /// Row gaps and the space beneath shorter items remain valid drop targets.
    static func insertionIndex(at point: CGPoint, frames: [CGRect]) -> Int {
        guard !frames.isEmpty else { return 0 }
        var rows: [Range<Int>] = []
        var start = 0
        for index in frames.indices.dropFirst() where abs(frames[index].minY - frames[start].minY) > 1 {
            rows.append(start..<index)
            start = index
        }
        rows.append(start..<frames.count)

        if point.y < frames[0].minY { return 0 }
        if point.y > frames.map(\.maxY).max()! { return frames.count }
        let row = rows.min { lhs, rhs in
            func distance(_ range: Range<Int>) -> CGFloat {
                let top = frames[range.lowerBound].minY
                let bottom = range.map { frames[$0].maxY }.max()!
                return max(top - point.y, point.y - bottom, 0)
            }
            return distance(lhs) < distance(rhs)
        }!
        return row.first { point.x < frames[$0].midX } ?? row.upperBound
    }
}
