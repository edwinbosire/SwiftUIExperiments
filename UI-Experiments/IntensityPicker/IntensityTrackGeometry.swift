//
//  IntensityTrackGeometry.swift
//  UI-Experiments
//
//  Pure layout maths for the track. Keeping it out of the view keeps the
//  snapping behaviour easy to reason about and trivial to unit test.
//

import CoreGraphics

struct IntensityTrackGeometry {
	let width: CGFloat
	let height: CGFloat
	let knobDiameter: CGFloat
	let stopCount: Int

	var knobRadius: CGFloat { knobDiameter / 2 }

	/// Knob centre at the first stop. At this position the fill has collapsed to
	/// a circle of the track height, which is what draws the ring around the knob.
	var minimumKnobCenter: CGFloat { height / 2 }

	var maximumKnobCenter: CGFloat { max(width - height / 2, minimumKnobCenter) }

	var travel: CGFloat { maximumKnobCenter - minimumKnobCenter }

	func progress(forIndex index: Int) -> CGFloat {
		guard stopCount > 1 else { return 0 }
		let clamped = min(max(index, 0), stopCount - 1)
		return CGFloat(clamped) / CGFloat(stopCount - 1)
	}

	func knobCenter(forProgress progress: CGFloat) -> CGFloat {
		minimumKnobCenter + travel * clamp(progress)
	}

	func knobCenter(forIndex index: Int) -> CGFloat {
		knobCenter(forProgress: progress(forIndex: index))
	}

	/// Turns a touch location into progress along the track.
	func progress(forLocation x: CGFloat) -> CGFloat {
		guard travel > 0 else { return 0 }
		return clamp((x - minimumKnobCenter) / travel)
	}

	func index(nearestTo progress: CGFloat) -> Int {
		guard stopCount > 1 else { return 0 }
		let raw = (clamp(progress) * CGFloat(stopCount - 1)).rounded()
		return min(max(Int(raw), 0), stopCount - 1)
	}

	/// The fill runs from the leading edge to just past the knob, leaving a ring
	/// of tint visible around it at every position.
	func fillWidth(forKnobCenter center: CGFloat) -> CGFloat {
		min(max(center + height / 2, height), width)
	}

	var stopCenters: [CGFloat] {
		guard stopCount > 0 else { return [] }
		return (0..<stopCount).map { knobCenter(forIndex: $0) }
	}

	private func clamp(_ value: CGFloat) -> CGFloat {
		min(max(value, 0), 1)
	}
}
