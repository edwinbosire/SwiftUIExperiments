//
//  Handbook.swift
//  UI-Experiments
//
//  Created by Edwin Bosire on 03/03/2025.
//

import Foundation
import SwiftUI

struct HandbookContentView: View {
	var body: some View {
		ZStack {
			Color(hex: "90e0ef")
				.ignoresSafeArea()

			VStack(spacing: 0) {
				// Main Content
				ScrollView {
					VStack(spacing: 24) {
						// Progress Card
						ProgressCard(progress: 0.04)

						// Bookmarks Card
						BookmarkCard()

						// Chapter 1
						ChapterSection(title: "Chapter 1: The values and principles of the UK...")

						// Chapter 1 Topics
						TopicRow(title: "The values and principles of the UK", isCompleted: true, color: .lightBlue)
						TopicRow(title: "Becoming a permanent citizen", isCompleted: true, color: .green)
						TopicRow(title: "Taking the life in the UK test", isCompleted: true, color: .lightBlue)

						// Chapter 2
						ChapterSection(title: "Chapter 2: What is the UK?")

						// Chapter 2 Topics
						LockedTopicRow(title: "What is the UK?")

						// Chapter 3
						ChapterSection(title: "Chapter 3: A long and illustrious history")

						// Add spacing at the bottom to ensure all content is visible
						Spacer().frame(height: 100)
					}
					.padding(.horizontal)
				}

				// Tab Bar
				TabBar()
			}
		}
	}
}

// Progress Card Component
struct ProgressCard: View {
	let progress: Double

	var body: some View {
		ZStack {
			RoundedRectangle(cornerRadius: 12)
				.fill(Color.white)
				.shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

			VStack(spacing: 16) {
				HStack {
					Text("Your overall study progress")
						.font(.system(size: 20, weight: .medium))
						.foregroundColor(.black)

					Spacer()

					Text("\(Int(progress * 100))%")
						.font(.system(size: 20, weight: .medium))
						.foregroundColor(.black)
				}

				ZStack(alignment: .leading) {
					RoundedRectangle(cornerRadius: 4)
						.fill(Color.gray.opacity(0.2))
						.frame(height: 8)

					RoundedRectangle(cornerRadius: 4)
						.fill(Color.blue)
						.frame(width: UIScreen.main.bounds.width * 0.75 * progress, height: 8)
				}
			}
			.padding()
		}
	}
}

// Bookmark Card Component
struct BookmarkCard: View {
	var body: some View {
		ZStack {
			RoundedRectangle(cornerRadius: 12)
				.fill(Color.white)
				.shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

			HStack(spacing: 16) {
				ZStack {
					Rectangle()
						.fill(Color.blue)
						.frame(width: 80)

					Image(systemName: "bookmark.fill")
						.font(.system(size: 32))
						.foregroundColor(.white)
				}

				VStack(alignment: .leading, spacing: 4) {
					HStack {
						Text("My bookmarks")
							.font(.system(size: 20, weight: .medium))

						Image(systemName: "lock.fill")
							.foregroundColor(.blue)
					}

					Text("Your bookmarked study pages")
						.font(.system(size: 16))
						.foregroundColor(.gray)
				}

				Spacer()
			}
		}
		.frame(height: 90)
	}
}

// Chapter Section Component
struct ChapterSection: View {
	let title: String

	var body: some View {
		HStack {
			Text(title)
				.font(.system(size: 20, weight: .semibold))
				.foregroundColor(.black)

			Spacer()
		}
		.padding(.top, 8)
	}
}

// Topic Row Component
struct TopicRow: View {
	let title: String
	let isCompleted: Bool
	let color: Color

	var body: some View {
		ZStack {
			RoundedRectangle(cornerRadius: 12)
				.fill(Color.white)
				.shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

			HStack(spacing: 16) {
				ZStack {
					Circle()
						.fill(color)
						.frame(width: 40, height: 40)

					Image(systemName: "checkmark")
						.font(.system(size: 20, weight: .bold))
						.foregroundColor(.white)
				}

				Text(title)
					.font(.system(size: 16, weight: .medium))

				Spacer()
			}
			.padding()
		}
		.frame(height: 70)
	}
}

// Locked Topic Row Component
struct LockedTopicRow: View {
	let title: String

	var body: some View {
		ZStack {
			RoundedRectangle(cornerRadius: 12)
				.fill(Color.white)
				.shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

			HStack(spacing: 16) {
				Image(systemName: "lock.fill")
					.font(.system(size: 20))
					.foregroundColor(.blue)

				Text(title)
					.font(.system(size: 16, weight: .medium))

				Spacer()
			}
			.padding()
		}
		.frame(height: 70)
	}
}

// Tab Bar Component
struct TabBar: View {
	var body: some View {
		HStack(spacing: 0) {
			TabBarItem(icon: "checkmark.square.fill", text: "Tests", isSelected: false)
			TabBarItem(icon: "rectangle.fill.on.rectangle.fill", text: "Flashcards", isSelected: false)
			TabBarItem(icon: "book.fill", text: "Handbook", isSelected: true)
			TabBarItem(icon: "ellipsis", text: "More", isSelected: false)
		}
		.frame(height: 60)
		.background(Color.white)
		.overlay(
			Rectangle()
				.frame(height: 1)
				.foregroundColor(Color.gray.opacity(0.3)),
			alignment: .top
		)
	}
}

// Tab Bar Item Component
struct TabBarItem: View {
	let icon: String
	let text: String
	let isSelected: Bool

	var body: some View {
		VStack(spacing: 4) {
			Image(systemName: icon)
				.font(.system(size: 22))
				.foregroundColor(isSelected ? .blue : .gray)

			Text(text)
				.font(.system(size: 12))
				.foregroundColor(isSelected ? .blue : .gray)
		}
		.frame(maxWidth: .infinity)
	}
}

// Custom Color Extension
extension Color {
	static let lightBlue = Color(hex: "C9DBF0")
	static let green = Color(hex: "00BFA5")

	init(hex: String) {
		let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
		var int: UInt64 = 0
		Scanner(string: hex).scanHexInt64(&int)
		let a, r, g, b: UInt64
		switch hex.count {
		case 3: // RGB (12-bit)
			(a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
		case 6: // RGB (24-bit)
			(a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
		case 8: // ARGB (32-bit)
			(a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
		default:
			(a, r, g, b) = (1, 1, 1, 0)
		}

		self.init(
			.sRGB,
			red: Double(r) / 255,
			green: Double(g) / 255,
			blue: Double(b) / 255,
			opacity: Double(a) / 255
		)
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		HandbookContentView()
	}
}
