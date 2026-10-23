//
//  UKTest.swift
//  UI-Experiments
//
//  Created by Edwin Bosire on 30/01/2025.
//

import Foundation
import SwiftUI

// Models
struct Question: Identifiable, Equatable {
	let id: UUID
	let text: String
	let choices: [String]
	let correctAnswer: Int
	let explanation: String
}

struct Exam: Identifiable {
	let id: UUID
	let title: String
	let questions: [Question]
}

class ExamState: ObservableObject {
	@Published var currentQuestionIndex = 0
	@Published var selectedAnswers: [Int?]
	@Published var timeRemaining = 45 * 60 // 45 minutes
	let exam: Exam
	let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

	init(exam: Exam) {
		self.exam = exam
		self.selectedAnswers = Array(repeating: nil, count: exam.questions.count)
	}

	var score: Double {
		let correct = selectedAnswers.enumerated().filter { index, answer in
			answer == exam.questions[index].correctAnswer
		}.count
		return Double(correct) / Double(exam.questions.count) * 100
	}

	var isPassed: Bool {
		score >= 75
	}
}

struct UKTestContentView: View {
	let exams = DataLoader.loadExams()

	var body: some View {
		NavigationStack {
			List(exams) { exam in
				NavigationLink(exam.title) {
					ExamView(examState: ExamState(exam: exam))
				}
			}
			.navigationTitle("Life in the UK Tests")
		}
	}
}

struct ExamView: View {
	@StateObject var examState: ExamState
	@State private var showResults = false

	var body: some View {
		VStack {
			if showResults {
				ResultsView(examState: examState)
			} else {
				QuestionView(examState: examState, showResults: $showResults)
			}
		}
		.onReceive(examState.timer) { _ in
			if examState.timeRemaining > 0 {
				examState.timeRemaining -= 1
			} else {
				showResults = true
			}
		}
	}
}

struct QuestionView: View {
	@ObservedObject var examState: ExamState
	@State private var wrongAnswer = false
	@Binding var showResults: Bool

	var question: Question {
		examState.exam.questions[examState.currentQuestionIndex]
	}

	var body: some View {
		VStack(spacing: 20) {
			HStack {
				Text("\(examState.timeRemaining / 60):\(String(format: "%02d", examState.timeRemaining % 60))")
				Spacer()
				Text("Question \(examState.currentQuestionIndex + 1) of \(examState.exam.questions.count)")
			}
			.padding()

			Text(question.text)
				.font(.title2)
				.padding()

			ForEach(question.choices.indices, id: \.self) { index in
				Button {
					handleAnswer(index)
				} label: {
					Text(question.choices[index])
						.frame(maxWidth: .infinity)
						.padding()
						.background(answerBackground(for: index))
						.cornerRadius(8)
				}
				.disabled(examState.selectedAnswers[examState.currentQuestionIndex] != nil)
			}

			if wrongAnswer {
				Text(question.explanation)
					.padding()
					.background(Color.red.opacity(0.1))
					.cornerRadius(8)

				Button("Next Question") {
					if examState.currentQuestionIndex < examState.exam.questions.count {
						examState.currentQuestionIndex += 1
						wrongAnswer = false
					} else {
						showResults = true
					}
				}
			}
		}
		.padding()
	}

	func handleAnswer(_ index: Int) {
		examState.selectedAnswers[examState.currentQuestionIndex] = index

		if index == question.correctAnswer {
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
				if examState.currentQuestionIndex < examState.exam.questions.count - 1 {
					examState.currentQuestionIndex += 1
				} else {
					showResults = true
				}
			}
		} else {
			withAnimation(.default) {
				wrongAnswer = true
			}
		}
	}

	func answerBackground(for index: Int) -> Color {
		if let selectedAnswer = examState.selectedAnswers[examState.currentQuestionIndex] {
			if selectedAnswer == index {
				return index == question.correctAnswer ? .green : .red
			}
		}
		return .blue.opacity(0.1)
	}
}

struct ResultsView: View {
	let examState: ExamState

	var body: some View {
		ScrollView {
			VStack(spacing: 20) {
				Text("Score: \(Int(examState.score))%")
					.font(.title)

				Text(examState.isPassed ? "Passed!" : "Failed")
					.font(.title2)
					.foregroundColor(examState.isPassed ? .green : .red)

				ForEach(examState.exam.questions.indices, id: \.self) { index in
					ResultQuestionView(
						question: examState.exam.questions[index],
						selectedAnswer: examState.selectedAnswers[index]
					)
				}
			}
			.padding()
		}
	}
}

struct ResultQuestionView: View {
	let question: Question
	let selectedAnswer: Int?

	var body: some View {
		VStack(alignment: .leading, spacing: 10) {
			Text(question.text)
				.font(.headline)

			if let selected = selectedAnswer,
			   selected != question.correctAnswer {
				Text("Your answer: \(question.choices[selected])")
					.foregroundColor(.red)
				Text("Correct answer: \(question.choices[question.correctAnswer])")
					.foregroundColor(.green)
				Text(question.explanation)
					.font(.caption)
			}
		}
		.padding()
		.background(Color.gray.opacity(0.1))
		.cornerRadius(8)
	}
}

struct Exam_Previews: PreviewProvider {
	static var previews: some View {
		UKTestContentView()
	}
}
// DataLoader.swift
struct ExamData: Codable {
	let exams: [ExamDTO]
}

struct ExamDTO: Codable {
	let id: String
	let title: String
	let questions: [QuestionDTO]
}

struct QuestionDTO: Codable {
	let id: String
	let text: String
	let choices: [String]
	let correctAnswer: Int
	let explanation: String
}

class DataLoader {
	static func loadExams() -> [Exam] {
		guard let data: Data = mockExam.data(using: .utf8),
			  let examData = try? JSONDecoder().decode(ExamData.self, from: data) else {
			return []
		}
		
		
		return examData.exams.map { dto in
			Exam(
				id: UUID(),
				title: dto.title,
				questions: dto.questions.map { q in
					Question(
						id: UUID(),
						text: q.text,
						choices: q.choices,
						correctAnswer: q.correctAnswer,
						explanation: q.explanation
					)
				}
			)
		}
	}
	
}
		// questions.json
		 let mockExam = """
{
   "exams": [
 {
  "id": "1",
  "title": "Practice Test 1",
  "questions": [
   {
	"id": "q1",
	"text": "What are the national flowers of England, Wales, Scotland, and Northern Ireland?",
	"choices": [
  "Rose, Daffodil, Thistle, Shamrock",
  "Tulip, Crocus, Heather, Clover",
  "Daisy, Leek, Bluebell, Flax",
  "Lily, Iris, Foxglove, Poppy"
	],
	"correctAnswer": 0,
	"explanation": "The rose (England), daffodil (Wales), thistle (Scotland), and shamrock (Northern Ireland) are the national flowers representing each nation."
   },
   {
	"id": "q2",
	"text": "Who was the first woman to sit in Parliament?",
	"choices": [
  "Margaret Thatcher",
  "Nancy Astor",
  "Barbara Castle",
  "Eleanor Rathbone"
	],
	"correctAnswer": 1,
	"explanation": "Nancy Astor was the first woman to take her seat in Parliament in 1919."
   }
  ]
 }
   ]
}
"""
