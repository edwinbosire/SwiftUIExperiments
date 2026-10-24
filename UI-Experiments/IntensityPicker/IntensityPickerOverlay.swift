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
    @ScaledMetric(relativeTo: .body) private var panelHeight = 150

	func body(content: Content) -> some View {
        GeometryReader { geometry in
         let inset = min(max(0, bottomInset), max(0, geometry.size.height - panelHeight))
         ZStack(alignment: .bottom) {
            if isPresented {
                content
                    .blur(radius: style.metrics.backdropBlur)
                    .overlay {
                        style.colors.backdrop
                            .ignoresSafeArea()
                            .onTapGesture { isPresented = false }
                    }
            } else {
                content
                    .transaction { $0.animation = nil }
            }

			if isPresented {
                ScrollView {
                    IntensityPicker(levels: levels, selection: $selection, style: style)
                        .accessibilityIdentifier("intensity-control")
                        .padding(.vertical, 16)
                        .padding(.horizontal, min(horizontalPadding, geometry.size.width * 0.1))
                        .frame(maxWidth: 740)
                        .frame(maxWidth: .infinity)
                }
                .scrollBounceBehavior(.basedOnSize)
                .frame(height: min(panelHeight, max(1, geometry.size.height - inset - 44)))
                .padding(.bottom, inset)
                .accessibilityIdentifier("intensity-picker-panel")
                .accessibilityAction(.escape) { isPresented = false }
                .transition(.scale(scale: 0.85, anchor: style.metrics.revealAnchor).combined(with: .opacity))
			}
		}
         .overlay(alignment: .topTrailing) {
             if isPresented {
                 Button { isPresented = false } label: {
                     Image(systemName: "xmark").frame(width: 44, height: 44)
                 }
                 .foregroundStyle(.white)
                 .accessibilityLabel("Close intensity picker")
                 .accessibilityIdentifier("close-intensity-picker")
             }
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
