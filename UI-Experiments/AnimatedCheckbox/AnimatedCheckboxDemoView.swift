import SwiftUI

struct AnimatedCheckboxDemoView: View {
	var body: some View {
		List {
			Row(text: "👨🏽‍💻 Write code everyday")
			Row(text: "🏋🏽 Weight training")
			Row(text: "🛒 Grocery shopping")
			Row(text: "🙏🏽 Say thanks")
		}
		.navigationTitle("Animated checkbox")
		.navigationBarTitleDisplayMode(.inline)
	}
}

private struct Row: View {
	@State private var isComplete = false
	let text: String
	let background: Color = .black.opacity(0.86)

	var body: some View {
		HStack {
			CheckMark(onTap: { isComplete.toggle() })
			Text(text)
				.font(.title3)
                .fixedSize(horizontal: false, vertical: true)
				.foregroundStyle(isComplete ? .gray : .white)
				.strikethrough(isComplete)
				.padding(.leading, 8.0)
		}
		.listRowBackground(background.lighten)
		.listRowSeparatorTint(.gray)
	}
}

private struct CheckMark: View {
	@State private var isComplete = false
	@State private var degrees = false
	@State private var opacity = false

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

#Preview {
	NavigationStack {
		AnimatedCheckboxDemoView()
	}
}
