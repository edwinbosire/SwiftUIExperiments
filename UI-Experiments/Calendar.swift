//
//  Calendar.swift
//  UI-Experiments
//
//  Created by Edwin Bosire on 28/02/2025.
//

import Foundation
import SwiftUI

// MARK: - Main Calendar View
struct CalendarView: View {
	@StateObject private var viewModel = CalendarViewModel()

	var body: some View {
		VStack(spacing: 20) {
			CalendarHeaderView(viewModel: viewModel)
			CalendarGridView(viewModel: viewModel)
		}
		.padding()
		.background(Color.gray.opacity(0.05))
	}
}

// MARK: - Header Component
struct CalendarHeaderView: View {
	@ObservedObject var viewModel: CalendarViewModel

	var body: some View {
		HStack {
			Text("December")
				.font(.largeTitle)
				.fontWeight(.bold)

			Spacer()

			NavigationButtonsView()

			Spacer()

			ViewModeToggleView(viewModel: viewModel)
		}
		.padding(.horizontal)
	}
}

// MARK: - Navigation Buttons Component
struct NavigationButtonsView: View {
	var body: some View {
		HStack(spacing: 15) {
			Button(action: {}) {
				Image(systemName: "chevron.left")
					.foregroundColor(.gray)
			}

			Button(action: {}) {
				Image(systemName: "chevron.right")
					.foregroundColor(.gray)
			}
		}
	}
}

// MARK: - View Mode Toggle Component
struct ViewModeToggleView: View {
	@ObservedObject var viewModel: CalendarViewModel

	var body: some View {
		HStack(spacing: 0) {
			Button(action: {
				viewModel.viewMode = .days
			}) {
				Text("Days")
					.padding(.vertical, 10)
					.padding(.horizontal, 20)
					.background(viewModel.viewMode == .days ? Color.white : Color.clear)
					.foregroundColor(viewModel.viewMode == .days ? .black : .gray)
					.cornerRadius(20)
			}

			Button(action: {
				viewModel.viewMode = .moods
			}) {
				Text("Moods")
					.padding(.vertical, 10)
					.padding(.horizontal, 20)
					.background(viewModel.viewMode == .moods ? Color.blue : Color.clear)
					.foregroundColor(viewModel.viewMode == .moods ? .white : .gray)
					.cornerRadius(20)
			}
		}
		.background(Color.gray.opacity(0.1))
		.cornerRadius(20)
	}
}

// MARK: - Calendar Grid Component
struct CalendarGridView: View {
	@ObservedObject var viewModel: CalendarViewModel

	var body: some View {
		VStack(spacing: 25) {
			WeekdayHeaderView(weekdays: viewModel.weekdays)
			DaysGridView(calendarDates: viewModel.calendarDates)
		}
		.padding()
		.background(Color.white)
	}
}

// MARK: - Weekday Header Component
struct WeekdayHeaderView: View {
	let weekdays: [String]

	var body: some View {
		HStack(spacing: 0) {
			ForEach(weekdays, id: \.self) { day in
				Text(day)
					.frame(maxWidth: .infinity)
					.foregroundColor(.gray)
					.font(.headline)
			}
		}
		.padding(.horizontal)
		.background(Color.gray.opacity(0.1))
		.cornerRadius(20)
	}
}

// MARK: - Days Grid Component
struct DaysGridView: View {
	let calendarDates: [[CalendarDay]]

	var body: some View {
		ForEach(0..<calendarDates.count, id: \.self) { row in
			HStack(spacing: 0) {
				ForEach(0..<calendarDates[row].count, id: \.self) { col in
					let day = calendarDates[row][col]
					CalendarDayView(day: day)
						.frame(maxWidth: .infinity)
				}
			}
		}
	}
}

// MARK: - Calendar Day View Component
struct CalendarDayView: View {
	let day: CalendarDay

	var body: some View {
		VStack {
			if let mood = day.mood {
				ZStack {
					Circle()
						.fill(moodColor(mood))
						.frame(width: 40, height: 40)

					moodIcon(mood)
						.foregroundColor(.white)
				}
				.overlay(
					Text(day.number)
						.font(.system(size: 16, weight: .bold))
						.foregroundColor(.clear)
				)
			} else {
				Text(day.number)
					.font(.system(size: 24, weight: .medium))
					.foregroundColor(.black)
					.frame(width: 40, height: 40)
			}
		}
	}

	func moodColor(_ mood: Mood) -> Color {
		switch mood {
		case .happy, .neutral:
			return .blue
		case .sad:
			return .red
		}
	}

	func moodIcon(_ mood: Mood) -> some View {
		Group {
			switch mood {
			case .happy:
				Image(systemName: "face.smiling")
			case .sad:
				Image(systemName: "face.frowning")
			case .neutral:
				Text("—")
					.font(.title2)
					.fontWeight(.bold)
			}
		}
	}
}

// MARK: - Models
enum Mood {
	case happy
	case sad
	case neutral
}

enum ViewMode {
	case days
	case moods
}

struct CalendarDay: Identifiable {
	let id = UUID()
	let number: String
	let mood: Mood?
}

// MARK: - ViewModel
class CalendarViewModel: ObservableObject {
	@Published var viewMode: ViewMode = .moods

	let weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

	// Calendar dates structure
	let calendarDates: [[CalendarDay]] = [
		[
			CalendarDay(number: "30", mood: nil),
			CalendarDay(number: "31", mood: nil),
			CalendarDay(number: "1", mood: nil),
			CalendarDay(number: "2", mood: nil),
			CalendarDay(number: "3", mood: nil),
			CalendarDay(number: "4", mood: nil),
			CalendarDay(number: "5", mood: nil)
		],
		[
			CalendarDay(number: "6", mood: nil),
			CalendarDay(number: "7", mood: nil),
			CalendarDay(number: "8", mood: .neutral),
			CalendarDay(number: "9", mood: .happy),
			CalendarDay(number: "10", mood: nil),
			CalendarDay(number: "11", mood: nil),
			CalendarDay(number: "12", mood: nil)
		],
		[
			CalendarDay(number: "13", mood: nil),
			CalendarDay(number: "14", mood: nil),
			CalendarDay(number: "15", mood: nil),
			CalendarDay(number: "16", mood: nil),
			CalendarDay(number: "17", mood: nil),
			CalendarDay(number: "18", mood: nil),
			CalendarDay(number: "19", mood: nil)
		],
		[
			CalendarDay(number: "20", mood: .sad),
			CalendarDay(number: "21", mood: nil),
			CalendarDay(number: "22", mood: nil),
			CalendarDay(number: "23", mood: nil),
			CalendarDay(number: "24", mood: nil),
			CalendarDay(number: "25", mood: nil),
			CalendarDay(number: "26", mood: .happy)
		],
		[
			CalendarDay(number: "27", mood: nil),
			CalendarDay(number: "28", mood: nil),
			CalendarDay(number: "29", mood: nil),
			CalendarDay(number: "30", mood: nil),
			CalendarDay(number: "1", mood: nil),
			CalendarDay(number: "2", mood: nil),
			CalendarDay(number: "3", mood: nil)
		]
	]
}

// MARK: - Preview Provider
struct CalendarView_Previews: PreviewProvider {
	static var previews: some View {
		CalendarView()
	}
}
