//
//  MockKeyboardView.swift
//  UI-Experiments
//
//  A decorative keyboard. The system keyboard cannot be dimmed or blurred by an
//  overlay, so the demo draws its own in order to reproduce the recording.
//

import SwiftUI

struct MockKeyboardView: View {
	/// Height of the keyboard inside the safe area. The demo uses it to line the
	/// picker up with the composer slot.
	static let height: CGFloat = 296

	private let rows = ["QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"]
	private let keyColor = Color(white: 0.27)
	private let modifierColor = Color(white: 0.18)

	var body: some View {
		VStack(spacing: 0) {
			predictions

			VStack(spacing: 11) {
				letters(rows[0])

				letters(rows[1])
					.padding(.horizontal, 20)

				HStack(spacing: 6) {
					utilityKey(symbol: "shift.fill", width: 42)
					letters(rows[2])
						.padding(.horizontal, 2)
					utilityKey(symbol: "delete.left", width: 42)
				}

				HStack(spacing: 6) {
					utilityKey(text: "123", width: 42)
					utilityKey(symbol: "face.smiling", width: 42)
					key("space", flexible: true)
					utilityKey(symbol: "return", width: 60)
				}
			}
			.padding(.horizontal, 3)
			.padding(.top, 10)

			HStack {
				Image(systemName: "globe")
				Spacer()
				Image(systemName: "mic")
			}
			.font(.system(size: 19))
			.foregroundStyle(.white)
			.padding(.horizontal, 22)
			.padding(.top, 16)

			Spacer(minLength: 0)
		}
		.frame(height: Self.height)
		.frame(maxWidth: .infinity)
		.background {
			Color(white: 0.13).ignoresSafeArea(edges: .bottom)
		}
		.accessibilityHidden(true)
		.allowsHitTesting(false)
	}

	private var predictions: some View {
		HStack(spacing: 0) {
			ForEach(["I", "The", "I'm"], id: \.self) { word in
				Text(word)
					.font(.system(size: 16))
					.foregroundStyle(.white)
					.frame(maxWidth: .infinity)
			}
		}
		.frame(height: 44)
	}

	private func letters(_ row: String) -> some View {
		HStack(spacing: 6) {
			ForEach(Array(row), id: \.self) { character in
				key(String(character))
			}
		}
	}

	private func key(_ label: String, flexible: Bool = false) -> some View {
		RoundedRectangle(cornerRadius: 5, style: .continuous)
			.fill(keyColor)
			.frame(height: 42)
			.frame(maxWidth: .infinity)
			.overlay {
				Text(flexible ? "" : label)
					.font(.system(size: 22))
					.foregroundStyle(.white)
			}
	}

	private func utilityKey(text: String? = nil, symbol: String? = nil, width: CGFloat) -> some View {
		RoundedRectangle(cornerRadius: 5, style: .continuous)
			.fill(modifierColor)
			.frame(width: width, height: 42)
			.overlay {
				Group {
					if let text {
						Text(text).font(.system(size: 15))
					} else if let symbol {
						Image(systemName: symbol).font(.system(size: 17))
					}
				}
				.foregroundStyle(.white)
			}
	}
}

#Preview {
	VStack {
		Spacer()
		MockKeyboardView()
	}
	.background(Color.black)
}
