# SwiftUIExperiments

# 1. Animated checkbox

Using layering technique to animate a check box when selected
![check box](/Resources/screen_recording.gif "Animated Checkbox")


```swift
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
```