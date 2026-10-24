//
//  StickyHeaderQuestionView.swift
//  UI-Experiments
//
//  Created by Edwin Bosire on 08/03/2025.
//

import SwiftUI

struct StickyHeaderQuestionView: View {
	// Track scroll positions
	@State private var scrollOffset: CGFloat = 0
	@State private var instructionPosition: CGFloat = 0
	@State private var originalQuestionPosition: CGFloat = 0

	// For debugging - helps us see when state changes
	@State private var selectedOptions: Set<String> = []

	// Quiz content
	let question = "Which TWO are British Overseas territories?"
	let options = ["St Helena", "Ireland", "The Falkland Islands", "Hawaii"]

	// Calculate if we should show the sticky header
	private var shouldShowStickyHeader: Bool {
		// The scrollOffset will be negative when scrolling down
		// We want to show the header when the original question moves off-screen (offset is negative)
		// And hide it when the instruction text approaches the top


		// True when question would be off screen AND instructions aren't too close
		return scrollOffset < -50 &&
			   instructionPosition > 150
	}

	var body: some View {
        GeometryReader { geometry in
		ZStack(alignment: .top) {
			// Background
			Color(hex: "0D3B39").ignoresSafeArea()
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
							.font(.largeTitle.bold())
                            .fixedSize(horizontal: false, vertical: true)
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
							.frame(height: min(300, geometry.size.height * 0.25))

						// Instructions text with position tracking
						Text("Please select TWO answers")
							.font(.title3)
                    .fixedSize(horizontal: false, vertical: true)
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
                    .frame(maxWidth: 820)
                    .frame(maxWidth: .infinity)
				}
			}
			.coordinateSpace(name: "scrollView")
			.onPreferenceChange(ScrollOffsetKey.self) {
				scrollOffset = $0
			}
			.onPreferenceChange(InstructionPositionKey.self) {
				instructionPosition = $0
			}
			.onPreferenceChange(OriginalQuestionPositionKey.self) {
				originalQuestionPosition = $0
			}

			// Sticky question header - always rendered but opacity changes
			VStack {
				Text(question)
					.font(.title2.bold())
                    .fixedSize(horizontal: false, vertical: true)
					.multilineTextAlignment(.center)
					.foregroundColor(.white)
					.padding(.horizontal)
					.padding(.vertical, 15)
					.frame(maxWidth: .infinity)
					.background(Color(hex: "0D3B39"))
			}
            .allowsHitTesting(false)
            .accessibilityHidden(!shouldShowStickyHeader)
			.opacity(shouldShowStickyHeader ? 1 : 0)
			.animation(.easeInOut(duration: 0.3), value: shouldShowStickyHeader)
			.zIndex(1)
		}
        }
        .navigationTitle("Quiz")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("quiz-screen")
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
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityIdentifier("quiz-answer-\(text)")
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
