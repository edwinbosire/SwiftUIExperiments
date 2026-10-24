//
//  ComposerBar.swift
//  UI-Experiments
//
//  A stand in for the message composer, close enough to the recording to show
//  the picker taking over the same slot.
//

import SwiftUI

struct ComposerBar: View {
	let level: IntensityLevel
	var placeholder: String = "Ask anything"
	var onIntensityTap: () -> Void

	@State private var caretVisible = true

	private let tint = Color(red: 0.22, green: 0.58, blue: 1.0)

	var body: some View {
		VStack(alignment: .leading, spacing: 20) {
			HStack(spacing: 3) {
				Capsule()
					.fill(tint)
					.frame(width: 2, height: 21)
					.opacity(caretVisible ? 1 : 0)

				Text(placeholder)
					.font(.body)
					.foregroundStyle(Color(white: 0.42))
			}

			HStack(spacing: 24) {
				icon("plus", size: 20)

				Spacer(minLength: 0)

				Button(action: onIntensityTap) {
					Image(systemName: level.systemImage ?? "gauge.with.dots.needle.bottom.50percent")
						.font(.system(size: 20))
						.foregroundStyle(tint)
						.contentTransition(.symbolEffect(.replace))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
				}
                .buttonStyle(.plain)
				.accessibilityLabel("Intensity")
				.accessibilityValue(level.displayName)
                .accessibilityIdentifier("show-intensity-picker")

				icon("mic", size: 20)

				Circle()
					.fill(tint)
					.frame(width: 34, height: 34)
					.overlay {
						Image(systemName: "waveform")
							.font(.system(size: 16, weight: .semibold))
							.foregroundStyle(.white)
					}
			}
		}
		.padding(.horizontal, 18)
		.padding(.top, 16)
		.padding(.bottom, 14)
		.background {
			RoundedRectangle(cornerRadius: 26, style: .continuous)
				.fill(Color(white: 0.11))
		}
		.onAppear {
			withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) {
				caretVisible = false
			}
		}
	}

	private func icon(_ name: String, size: CGFloat) -> some View {
		Image(systemName: name)
			.font(.system(size: size))
			.foregroundStyle(.white)
	}
}
