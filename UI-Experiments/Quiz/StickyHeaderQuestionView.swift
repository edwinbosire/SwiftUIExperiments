//
//  StickyHeaderQuestionView.swift
//  UI-Experiments
//
//  Created by Edwin Bosire on 08/03/2025.
//

import SwiftUI

import SwiftUI

struct StickyHeaderQuestionView: View {
	// Track scroll positions
	@State private var scrollOffset: CGFloat = 0
	@State private var instructionPosition: CGFloat = 0
	@State private var originalQuestionPosition: CGFloat = 0

	// For debugging - helps us see when state changes
	@State private var debugText: String = ""
	@State private var selectedOptions: Set<String> = []

	// Quiz content
	let question = "Which TWO are British Overseas territories?"
	let options = ["St Helena", "Ireland", "The Falkland Islands", "Hawaii"]

	// Calculate if we should show the sticky header
	private var shouldShowStickyHeader: Bool {
		// The scrollOffset will be negative when scrolling down
		// We want to show the header when the original question moves off-screen (offset is negative)
		// And hide it when the instruction text approaches the top

		// Debug print for troubleshooting
		print("Scroll: \(scrollOffset), Question: \(originalQuestionPosition), Instruction: \(instructionPosition)")

		// True when question would be off screen AND instructions aren't too close
		return scrollOffset < -50 &&
			   instructionPosition > 150
	}

	var body: some View {
		ZStack(alignment: .top) {
			// Background
			Color(hex: "0D3B39").ignoresSafeArea()
			Text("\(debugText)")
				.font(.caption)
				.foregroundStyle(Color.red)
			// Scroll content
			ScrollView {
				ZStack(alignment: .top) {
					// Improved tracking view for scroll position
					GeometryReader { geometry in
						let offset = geometry.frame(in: .named("scrollView")).minY
						Color.clear
							.preference(key: ScrollOffsetKey.self, value: offset)
							.onAppear {
								// Initialize scroll position when view appears
								DispatchQueue.main.async {
									scrollOffset = offset
								}
							}
					}
					.frame(height: 0)

					VStack(spacing: 0) {
						// Top navigation
						HStack {
							Text("Mock Test")
								.font(.title2)
								.fontWeight(.bold)
								.foregroundColor(.white)
							Spacer()
							Image(systemName: "bookmark")
								.foregroundColor(.white)
							Image(systemName: "ellipsis.circle")
								.foregroundColor(.white)
								.padding(.leading, 8)
						}
						.padding()

						// Question info
						HStack {
							Text("Question 1 of 25")
								.foregroundColor(.white)
							Spacer()
							HStack(spacing: 2) {
								Image(systemName: "clock")
								Text("04:59")
							}
							.foregroundColor(.white)
						}
						.padding(.horizontal)
						.padding(.bottom, 10)

						// Original question (will scroll away)
						Text(question)
							.font(.system(size: 32, weight: .bold))
							.multilineTextAlignment(.center)
							.foregroundColor(.white)
							.padding(.horizontal)
							.padding(.vertical, 30)
							.background(
								GeometryReader { geometry in
									Color.clear.preference(
										key: OriginalQuestionPositionKey.self,
										value: geometry.frame(in: .named("scrollView")).minY
									)
								}
							)

						// Spacing to simulate content
						Spacer()
							.frame(height: 300)

						// Instructions text with position tracking
						Text("Please select TWO answers")
							.font(.title3)
							.foregroundColor(.white)
							.frame(maxWidth: .infinity, alignment: .leading)
							.padding()
							.background(
								GeometryReader { geometry in
									Color.clear.preference(
										key: InstructionPositionKey.self,
										value: geometry.frame(in: .named("scrollView")).minY
									)
								}
							)

						// Answer options
						VStack(spacing: 14) {
							ForEach(options, id: \.self) { option in
								AnswerOptionButton(
									text: option,
									isSelected: selectedOptions.contains(option),
									action: {
										if selectedOptions.contains(option) {
											selectedOptions.remove(option)
										} else if selectedOptions.count < 2 {
											selectedOptions.insert(option)
										}
									}
								)
							}
						}
						.padding(.horizontal)
						.padding(.bottom, 40)
					}
				}
			}
			.coordinateSpace(name: "scrollView")
			.onPreferenceChange(ScrollOffsetKey.self) {
				scrollOffset = $0
				debugText = "Scroll: \(Int(scrollOffset)) Question: \(Int(originalQuestionPosition)) Instr: \(Int(instructionPosition))"
			}
			.onPreferenceChange(InstructionPositionKey.self) {
				instructionPosition = $0
				debugText = "Scroll: \(Int(scrollOffset)) Question: \(Int(originalQuestionPosition)) Instr: \(Int(instructionPosition))"
			}
			.onPreferenceChange(OriginalQuestionPositionKey.self) {
				originalQuestionPosition = $0
				debugText = "Scroll: \(Int(scrollOffset)) Question: \(Int(originalQuestionPosition)) Instr: \(Int(instructionPosition))"
			}

			// Sticky question header - always rendered but opacity changes
			VStack {
				Text(question)
					.font(.system(size: 24, weight: .bold))
					.multilineTextAlignment(.center)
					.foregroundColor(.white)
					.padding(.horizontal)
					.padding(.vertical, 15)
					.frame(maxWidth: .infinity)
					.background(Color(hex: "0D3B39"))
			}
			.opacity(shouldShowStickyHeader ? 1 : 0)
			.animation(.easeInOut(duration: 0.3), value: shouldShowStickyHeader)
			.zIndex(1)
		}
	}
}

// Answer option button
struct AnswerOptionButton: View {
	let text: String
	let isSelected: Bool
	let action: () -> Void

	var body: some View {
		Button(action: action) {
			HStack {
				Circle()
					.strokeBorder(Color(hex: "00AA78"), lineWidth: 2)
					.frame(width: 24, height: 24)
					.overlay(
						Circle()
							.fill(isSelected ? Color(hex: "00AA78") : Color.clear)
							.frame(width: 16, height: 16)
					)

				Text(text)
					.font(.title3)
					.foregroundColor(Color(hex: "00AA78"))

				Spacer()
			}
			.padding()
			.background(Color.white)
			.cornerRadius(8)
		}
		.buttonStyle(PlainButtonStyle())
	}
}

// Preference keys for tracking positions
struct ScrollOffsetKey: PreferenceKey {
	static var defaultValue: CGFloat = 0
	static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
		value = nextValue()
	}
}

struct InstructionPositionKey: PreferenceKey {
	static var defaultValue: CGFloat = 0
	static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
		value = nextValue()
	}
}

struct OriginalQuestionPositionKey: PreferenceKey {
	static var defaultValue: CGFloat = 0
	static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
		value = nextValue()
	}
}

#Preview {
    StickyHeaderQuestionView()
}
