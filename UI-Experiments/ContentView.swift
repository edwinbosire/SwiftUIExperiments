//
//  ContentView.swift
//  UI-Experiments
//
//  Created by Edwin Bosire on 25/08/2024.
//

import SwiftUI

struct ContentView: View {
	var body: some View {
		NavigationStack {
			List {
				Row(text: "👨🏽‍💻 Write code everyday")
				Row(text: "🏋🏽 Weight training")
				Row(text: "🛒 Grocery shopping")
				Row(text: "🙏🏽 Say thanks")
			}
			.background(.black)
			.navigationTitle("Daily Rituals")
			.navigationBarTitleDisplayMode(.large)
		}

	}
}

struct Row: View {
	@State private var isComplete = false
	let text: String
	let background: Color = .black.opacity(0.86)
	var body: some View {
		HStack {
			CheckMark(onTap: { isComplete.toggle() })
			Text(text)
				.font(.title3)
				.foregroundStyle(isComplete ? .gray : .white)
				.strikethrough(isComplete)
				.padding(.leading, 8.0)
		}
		.listRowBackground(background)
		.listRowSeparatorTint(.gray)
	}
}
struct CheckMark: View {
	@State var isComplete: Bool = false
	@State var degrees = false
	@State var opacity = false

	private let cornerRadius = 12.0
	private let size = 40.0
	var onTap: (() -> Void)?
	var body: some View {
		ZStack {
			RoundedRectangle(cornerRadius: cornerRadius)
				.frame(width: size, height: size)
				.foregroundColor(.blue)
				.scaleEffect(isComplete ? 1.8 : 0)
				.opacity(opacity ? 0 : 0.5)

			RoundedRectangle(cornerRadius: isComplete ? cornerRadius : 20.0)
				.frame(width: size, height: size)
				.foregroundColor(isComplete ? .blue : .white)

			Image(systemName: "checkmark").bold()
				.opacity(isComplete ? 1.0 : 0.1)
				.foregroundColor(isComplete ? .white : .gray)
		}
		.rotationEffect(.degrees(degrees ? -20.0 : 0.0))
		.onTapGesture {
			onTap?()
			withAnimation {
				isComplete.toggle()
			}

			withAnimation(.easeInOut(duration: 0.5).delay(0.2)) {
				degrees.toggle()
				opacity.toggle()
			}

			withAnimation(.easeInOut(duration: 0.5).delay(0.7)) {
				degrees.toggle()
			}
		}
	}
}

struct CheckMarkPreview: View {
	@State private var isComplete = false
	var body: some View {
		ZStack {
			Color.black.ignoresSafeArea()
			CheckMark()
		}

	}
}
#Preview {
    ContentView()
//	CheckMarkPreview()
}
