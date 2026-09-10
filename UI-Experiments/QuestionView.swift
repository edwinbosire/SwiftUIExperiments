//
//  QuestionView.swift
//  UI-Experiments
//
//  Created by Edwin Bosire on 28/02/2025.
//

import Foundation

import SwiftUI

struct QuizView: View {
	@State private var selectedAnswers: Set<Int> = []

	let options = ["St Helena", "Ireland", "The Falkland Islands", "Hawaii"]

	var body: some View {
		NavigationView {
			ZStack {
				// Background gradient
				LinearGradient(
					gradient: Gradient(colors: [Color.white, Color.purple.opacity(0.1)]),
					startPoint: .top,
					endPoint: .bottom
				)
				.edgesIgnoringSafeArea(.all)

				VStack(spacing: 0) {
					// Question area
					VStack(alignment: .leading, spacing: 16) {
						HStack {
							Image(systemName: "clock")
								.foregroundColor(.gray)
							Text("04:59")
								.foregroundColor(.gray)
						}
						.frame(maxWidth: .infinity, alignment: .trailing)
						.padding(.bottom, 10)

						Text("Which TWO are British\nOverseas territories?")
							.font(.system(size: 32, weight: .medium))
							.foregroundColor(Color(UIColor.darkGray))
							.multilineTextAlignment(.leading)
							.padding(.bottom, 40)
					}
					.padding(.horizontal, 20)
					.padding(.top, 20)
					.frame(maxWidth: .infinity)

					Spacer()

					// Instructions
					Text("Please select TWO answers")
						.font(.system(size: 22))
						.foregroundColor(.gray)
						.padding(.bottom, 20)

					// Answer options
					VStack(spacing: 16) {
						ForEach(0..<options.count, id: \.self) { index in
							Button(action: {
								toggleSelection(index)
							}) {
								HStack {
									Circle()
										.strokeBorder(Color.gray, lineWidth: 1)
										.background(
											selectedAnswers.contains(index) ?
											Circle().fill(Color.blue) :
											Circle().fill(Color.white)
										)
										.frame(width: 24, height: 24)

									Text(options[index])
										.font(.system(size: 22))
										.foregroundColor(.black)
										.padding(.leading, 10)

									Spacer()
								}
								.padding(.vertical, 16)
								.padding(.horizontal, 20)
								.background(Color.white)
								.cornerRadius(12)
							}
							.buttonStyle(PlainButtonStyle())
						}
					}
					.padding(.horizontal, 20)

					Spacer()

					// Bottom indicator
					Capsule()
						.fill(Color.gray)
						.frame(width: 40, height: 5)
						.padding(.bottom, 10)
				}
			}
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .principal) {
					HStack {
						Text("Mock Test")
							.font(.system(size: 22, weight: .bold))
							.foregroundColor(.blue)
						Spacer()
						Button(action: {}) {
							Image(systemName: "bookmark")
								.foregroundColor(.gray)
						}
						Button(action: {}) {
							Image(systemName: "ellipsis.circle")
								.foregroundColor(.gray)
						}
					}
				}
			}
		}
	}

	func toggleSelection(_ index: Int) {
		if selectedAnswers.contains(index) {
			selectedAnswers.remove(index)
		} else {
			// If already selected 2 items, remove the first one
			if selectedAnswers.count >= 2 {
				if let first = selectedAnswers.first {
					selectedAnswers.remove(first)
				}
			}
			selectedAnswers.insert(index)
		}
	}
}

struct QuizView_Previews: PreviewProvider {
	static var previews: some View {
		QuizView()
	}
}
