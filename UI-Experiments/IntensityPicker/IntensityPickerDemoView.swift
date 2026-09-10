//
//  IntensityPickerDemoView.swift
//  UI-Experiments
//
//  Puts the pieces together: a composer above a keyboard, a gauge button that
//  reveals the picker in the composer's slot, and a tap outside to dismiss.
//

import SwiftUI

struct IntensityPickerDemoView: View {
	private let levels = IntensityLevel.standard

	@State private var selection = IntensityLevel.medium.id
	@State private var isPickerPresented = false

	private var level: IntensityLevel {
		levels.first { $0.id == selection } ?? levels[0]
	}

	var body: some View {
		ZStack(alignment: .bottom) {
			Color.black.ignoresSafeArea()

			VStack(spacing: 0) {
				Spacer(minLength: 0)

				ComposerBar(level: level) {
					isPickerPresented = true
				}
				.padding(.horizontal, 12)
				.padding(.bottom, 10)
				.opacity(isPickerPresented ? 0 : 1)

				MockKeyboardView()
			}
		}
		.intensityPicker(isPresented: $isPickerPresented,
						 levels: levels,
						 selection: $selection,
						 bottomInset: MockKeyboardView.height + 24)
		.background(Color.black)
		.preferredColorScheme(.dark)
		.navigationTitle("Intensity Picker")
		.navigationBarTitleDisplayMode(.inline)
		.toolbarBackground(Color.black, for: .navigationBar)
		.toolbarBackground(.visible, for: .navigationBar)
		// The navigation bar sits outside the overlay, so it would stay crisp
		// while everything else blurs. Take it away for the duration.
		.toolbar(isPickerPresented ? .hidden : .visible, for: .navigationBar)
		.animation(.easeOut(duration: 0.25), value: isPickerPresented)
	}
}

#Preview {
	NavigationStack {
		IntensityPickerDemoView()
	}
	.preferredColorScheme(.dark)
}
