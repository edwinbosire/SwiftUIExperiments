//
//  QuestionViewv2.swift
//  UI-Experiments
//
//  Created by Edwin Bosire on 28/02/2025.
//

import Foundation
import SwiftUI

struct QuizQuestionView: View {
	// For the radio button selection state
	@State private var selectedAnswer: String? = "New Delhi"

	// Options with their states (correct/incorrect)
	let options = [
		(text: "Bangalore", isSelected: false, isCorrect: false),
		(text: "Kolkata", isSelected: true, isCorrect: false),
		(text: "New Delhi", isSelected: true, isCorrect: true),
		(text: "Mumbai", isSelected: false, isCorrect: false)
	]

	// For the explanation dropdown
	@State private var showExplanation = true

	var body: some View {
		VStack(spacing: 0) {
			// Navigation bar
			NavigationBar()

			// Blue indicator line
			Rectangle()
				.fill(Color.blue)
				.frame(height: 4)

			ScrollView {
				VStack(alignment: .leading, spacing: 0) {
					// Question badge
					HStack {
						Text("Question 15 of 24")
							.font(.system(size: 14))
							.padding(.horizontal, 12)
							.padding(.vertical, 6)
							.foregroundColor(.white)
							.background(Color.blue)
							.clipShape(Capsule())
							.padding(.top, 20)
							.padding(.bottom, 16)
					}
					.padding(.horizontal, 20)

					// Question text
					Text("In the 20th century, what did Sir Edwin Lutyens design to be the seat of government in India?")
						.font(.system(size: 22, weight: .medium))
						.foregroundColor(.black)
						.padding(.horizontal, 20)
						.padding(.bottom, 32)

					Spacer(minLength: 200)

					// Answer options
					VStack(spacing: 0) {
						ForEach(0..<options.count, id: \.self) { index in
							let option = options[index]

							Button(action: {}) {
								HStack {
									Group {
										if option.isSelected {
											if option.isCorrect {
												Image(systemName: "checkmark.circle.fill")
													.foregroundColor(.white)
											} else {
												Image(systemName: "xmark.circle.fill")
													.foregroundColor(.white)
											}
										} else {
											Circle()
												.strokeBorder(Color.gray, lineWidth: 1)
												.background(Circle().fill(Color.white))
										}
									}
									.frame(width: 24, height: 24)

									Text(option.text)
										.font(.system(size: 16))
										.foregroundColor(option.isSelected ? .white : .black)
										.padding(.leading, 10)

									Spacer()
								}
								.frame(maxWidth: .infinity)
								.padding(.vertical, 16)
								.padding(.horizontal, 20)
								.background(
									option.isSelected
										? (option.isCorrect ? Color.green : Color.red)
										: Color.white
								)
							}
							.buttonStyle(PlainButtonStyle())
							.padding(.bottom, 1) // Small gap between options
						}
					}

					// Explanation section
					VStack(alignment: .leading, spacing: 0) {
						Button(action: {
							withAnimation {
								showExplanation.toggle()
							}
						}) {
							HStack {
								Image(systemName: showExplanation ? "chevron.down" : "chevron.right")
									.foregroundColor(.blue)

								Text("EXPLANATION")
									.font(.system(size: 14, weight: .semibold))
									.foregroundColor(.blue)

								Spacer()
							}
							.padding(.vertical, 16)
							.padding(.horizontal, 20)
							.background(Color(UIColor.systemGray6))
						}
						.buttonStyle(PlainButtonStyle())

						if showExplanation {
							Text("In the 20th century, Sir Edwin Lutyens had an influence throughout the British Empire. He designed New Delhi to be the seat of government in India. After the First World War, he was responsible for many war memorials throughout the world, including the Cenotaph in Whitehall.")
								.font(.system(size: 14))
								.padding(20)
								.background(Color(UIColor.systemGray6))
						}
					}
				}
			}
		}
		.edgesIgnoringSafeArea(.bottom)
		.background(Color(UIColor.systemGray6))
	}
}

struct NavigationBar: View {
	var body: some View {
		HStack {
			Button(action: {}) {
				HStack(spacing: 2) {
					Image(systemName: "chevron.left")
						.font(.system(size: 16, weight: .semibold))
					Text("Back")
						.font(.system(size: 16, weight: .medium))
				}
				.foregroundColor(.blue)
			}

			Spacer()

			Text("Mock Test")
				.font(.system(size: 17, weight: .semibold))
				.foregroundColor(Color.blue)

			Spacer()

			HStack(spacing: 16) {
				Button(action: {}) {
					Image(systemName: "star")
						.font(.system(size: 20))
						.foregroundColor(.gray)
				}

				Button(action: {}) {
					Image(systemName: "line.3.horizontal")
						.font(.system(size: 20))
						.foregroundColor(.gray)
				}
			}
		}
		.padding(.horizontal, 16)
		.padding(.vertical, 12)
		.background(Color.white)
	}
}

struct QuizQuestionView_Previews: PreviewProvider {
	static var previews: some View {
		QuizQuestionView()
	}
}
