//
//  IntensityPicker.swift
//  UI-Experiments
//
//  A three stop intensity slider: drag the knob and it tracks your finger, the
//  fill follows it, the readout updates as you cross each stop and the knob
//  springs onto the nearest stop when you let go.
//

import SwiftUI

struct IntensityPicker: View {
	let levels: [IntensityLevel]
	@Binding var selection: IntensityLevel.ID
	var style: IntensityPickerStyle = .default
	var showsReadout: Bool = true
	var accessibilityTitle: String = "Intensity"

	/// Non nil only while a drag is in flight. The knob follows this value
	/// directly so scrubbing never lags behind the finger.
	@State private var dragProgress: CGFloat?
	/// Distance between the finger and the knob centre when the drag started,
	/// so grabbing the edge of the knob does not snap it under the fingertip.
	@State private var grabOffset: CGFloat = 0
	@State private var isDragging = false

	@Environment(\.accessibilityReduceMotion) private var reduceMotion

	var body: some View {
		VStack(spacing: style.metrics.readoutSpacing) {
			if showsReadout {
				readout
			}
			container
		}
		.sensoryFeedback(.selection, trigger: selectedIndex)
		.accessibilityElement(children: .ignore)
		.accessibilityLabel(accessibilityTitle)
		.accessibilityValue(selectedLevel?.displayName ?? "")
		.accessibilityAdjustableAction(adjust)
	}

	// MARK: Pieces

	private var readout: some View {
		ZStack {
			Text(selectedLevel?.displayName ?? "")
				.font(style.typography.readout)
				.foregroundStyle(style.colors.readout)
				.transition(.opacity.combined(with: .offset(y: 4)))
				.id(selection)
		}
		.animation(style.motion.readout, value: selection)
	}

	private var container: some View {
		GeometryReader { proxy in
			track(width: proxy.size.width)
		}
		.frame(height: style.metrics.trackHeight)
		.padding(.horizontal, style.metrics.containerInset.width)
		.padding(.vertical, style.metrics.containerInset.height)
		.background {
			Capsule(style: .continuous)
				.fill(style.colors.container)
				.overlay {
					Capsule(style: .continuous)
						.strokeBorder(style.colors.containerStroke, lineWidth: 1)
				}
		}
	}

	private func track(width: CGFloat) -> some View {
		let layout = trackGeometry(for: width)
		let center = layout.knobCenter(forProgress: currentProgress)
		let fillWidth = layout.fillWidth(forKnobCenter: center)
		let midY = style.metrics.trackHeight / 2

		return ZStack(alignment: .leading) {
			Capsule(style: .continuous)
				.fill(style.colors.track)

			Capsule(style: .continuous)
				.fill(style.colors.fill)
				.frame(width: fillWidth)

			ForEach(Array(layout.stopCenters.enumerated()), id: \.offset) { stop in
				Circle()
					.fill(stop.element < fillWidth - 1 ? style.colors.stopOnFill : style.colors.stop)
					.frame(width: style.metrics.stopDiameter,
						   height: style.metrics.stopDiameter)
					.position(x: stop.element, y: midY)
			}

			knob.position(x: center, y: midY)
		}
		.contentShape(Rectangle())
		.gesture(drag(in: layout))
	}

	private var knob: some View {
		Circle()
			.fill(style.colors.knob)
			.frame(width: style.metrics.knobDiameter,
				   height: style.metrics.knobDiameter)
			.shadow(color: style.colors.knobShadow,
					radius: isDragging ? 10 : 6,
					x: 0,
					y: 2)
			.scaleEffect(isDragging ? style.metrics.knobPressedScale : 1)
			.animation(snapAnimation, value: isDragging)
	}

	// MARK: Interaction

	private func drag(in layout: IntensityTrackGeometry) -> some Gesture {
		DragGesture(minimumDistance: 0)
			.onChanged { value in
				if isDragging {
					dragProgress = layout.progress(forLocation: value.location.x - grabOffset)
				} else {
					begin(value, in: layout)
				}
				commitSelection(for: dragProgress ?? currentProgress, in: layout)
			}
			.onEnded { _ in
				let landing = layout.index(nearestTo: dragProgress ?? currentProgress)
				withAnimation(snapAnimation) {
					dragProgress = nil
					isDragging = false
					select(landing)
				}
			}
	}

	/// A touch that lands on the knob picks it up where it is. A touch anywhere
	/// else on the track pulls the knob over to the finger.
	private func begin(_ value: DragGesture.Value, in layout: IntensityTrackGeometry) {
		isDragging = true

		let knobCenter = layout.knobCenter(forIndex: selectedIndex)
		let distance = abs(value.startLocation.x - knobCenter)
		let grabbedKnob = distance <= layout.knobRadius + style.metrics.grabTolerance

		grabOffset = grabbedKnob ? value.startLocation.x - knobCenter : 0

		let progress = layout.progress(forLocation: value.location.x - grabOffset)
		if grabbedKnob {
			dragProgress = progress
		} else {
			withAnimation(snapAnimation) {
				dragProgress = progress
			}
		}
	}

	private func commitSelection(for progress: CGFloat, in layout: IntensityTrackGeometry) {
		let index = layout.index(nearestTo: progress)
		guard levels.indices.contains(index), levels[index].id != selection else { return }
		selection = levels[index].id
	}

	private func select(_ index: Int) {
		guard levels.indices.contains(index) else { return }
		selection = levels[index].id
	}

	private func adjust(_ direction: AccessibilityAdjustmentDirection) {
		let next = direction == .increment ? selectedIndex + 1 : selectedIndex - 1
		guard levels.indices.contains(next) else { return }
		withAnimation(snapAnimation) {
			select(next)
		}
	}

	// MARK: Derived state

	private func trackGeometry(for width: CGFloat) -> IntensityTrackGeometry {
		IntensityTrackGeometry(width: width,
							   height: style.metrics.trackHeight,
							   knobDiameter: style.metrics.knobDiameter,
							   stopCount: levels.count)
	}

	private var selectedIndex: Int {
		levels.firstIndex { $0.id == selection } ?? 0
	}

	private var selectedLevel: IntensityLevel? {
		levels.indices.contains(selectedIndex) ? levels[selectedIndex] : nil
	}

	private var currentProgress: CGFloat {
		if let dragProgress { return dragProgress }
		guard levels.count > 1 else { return 0 }
		return CGFloat(selectedIndex) / CGFloat(levels.count - 1)
	}

	private var snapAnimation: Animation {
		style.motion.snapAnimation(reduceMotion: reduceMotion)
	}
}

#Preview("Picker") {
	struct Harness: View {
		@State private var selection = IntensityLevel.medium.id

		var body: some View {
			ZStack {
				Color(white: 0.07).ignoresSafeArea()
				IntensityPicker(levels: IntensityLevel.standard, selection: $selection)
					.padding(.horizontal, 44)
			}
		}
	}

	return Harness()
}
