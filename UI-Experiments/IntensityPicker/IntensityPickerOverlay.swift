//
//  IntensityPickerOverlay.swift
//  UI-Experiments
//
//  Presents the picker the way the recording does: the content behind blurs and
//  dims, the panel grows out of the button that opened it, and a tap anywhere
//  outside puts it away.
//

import SwiftUI

struct IntensityPickerOverlay: ViewModifier {
	@Binding var isPresented: Bool
	let levels: [IntensityLevel]
	@Binding var selection: IntensityLevel.ID
	var bottomInset: CGFloat
	var horizontalPadding: CGFloat
	var style: IntensityPickerStyle

	@Environment(\.accessibilityReduceMotion) private var reduceMotion

	func body(content: Content) -> some View {
		ZStack(alignment: .bottom) {
			content
				.blur(radius: isPresented ? style.metrics.backdropBlur : 0)
				.overlay {
					style.colors.backdrop
						.opacity(isPresented ? 1 : 0)
						.ignoresSafeArea()
						.allowsHitTesting(isPresented)
						.onTapGesture { isPresented = false }
				}

			if isPresented {
				IntensityPicker(levels: levels,
								selection: $selection,
								style: style)
					.padding(.horizontal, horizontalPadding)
					.padding(.bottom, bottomInset)
					.transition(
						.scale(scale: 0.85, anchor: style.metrics.revealAnchor)
						.combined(with: .opacity)
					)
			}
		}
		.animation(style.motion.revealAnimation(reduceMotion: reduceMotion), value: isPresented)
	}
}

extension View {
	/// Overlays the intensity picker above this view.
	/// - Parameter bottomInset: distance from the bottom of this view to the
	///   bottom of the panel, so it can sit in the slot the composer occupies.
	func intensityPicker(isPresented: Binding<Bool>,
						 levels: [IntensityLevel],
						 selection: Binding<IntensityLevel.ID>,
						 bottomInset: CGFloat = 0,
						 horizontalPadding: CGFloat = 44,
						 style: IntensityPickerStyle = .default) -> some View {
		modifier(IntensityPickerOverlay(isPresented: isPresented,
										levels: levels,
										selection: selection,
										bottomInset: bottomInset,
										horizontalPadding: horizontalPadding,
										style: style))
	}
}
