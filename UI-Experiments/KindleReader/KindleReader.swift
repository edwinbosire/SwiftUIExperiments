import SwiftUI

// MARK: - Main View
struct KindleReaderView: View {
	@State private var fontSize: CGFloat = 18
	@State private var brightness: Double = 0.8
	@State private var selectedFont = "Bookerly"

	let fonts = [
		"Amazon Ember Bold",
		"Baskerville",
		"Bookerly",
		"Caecilia"
	]

	var body: some View {
		ZStack {
			// Main background
			Color.black.edgesIgnoringSafeArea(.all)

			VStack(spacing: 0) {
				// Reading content area
				ReadingContentView(fontSize: fontSize)

				// Bottom settings panel
				SettingsPanelView(
					fontSize: $fontSize,
					brightness: $brightness,
					selectedFont: $selectedFont,
					fonts: fonts
				)
			}
		}
		.brightness(brightness - 0.5)
	}
}

// MARK: - Reading Content View
struct ReadingContentView: View {
	let fontSize: CGFloat

	var body: some View {
		VStack(spacing: 20) {
			// Header with title and decoration
			ChapterHeaderView(title: "Introduction")

			// Text content
			BookContentView(content: bookContent, fontSize: fontSize)

			Spacer()
		}
	}

	// Sample content
	private var bookContent: String {
		"Without calculus, we wouldn't have cell phones, computers, or microwave ovens. We wouldn't have radio. Or television. Or ultra-sound for expectant mothers, or GPS for lost travelers. We wouldn't have split the atom, unraveled the human genome, or put astronauts on the moon. We might not even have"
	}
}

// MARK: - Chapter Header View
struct ChapterHeaderView: View {
	let title: String

	var body: some View {
		ZStack {
			Rectangle()
				.fill(Color.white)
				.frame(height: 190)

			HStack {
				Spacer()

				Text(title)
					.font(.system(size: 26, weight: .medium))
					.foregroundColor(.black)

				Spacer()

				// Decorative curved line
				DecorativeSwirl()
					.offset(x: 10)
			}
			.padding(.horizontal)
		}
	}
}

// MARK: - Decorative Swirl
struct DecorativeSwirl: View {
	var body: some View {
		Image(systemName: "curlybraces")
			.resizable()
			.aspectRatio(contentMode: .fit)
			.frame(width: 80, height: 140)
			.foregroundColor(.gray.opacity(0.5))
			.rotationEffect(.degrees(90))
	}
}

// MARK: - Book Content View
struct BookContentView: View {
	let content: String
	let fontSize: CGFloat

	var body: some View {
		ScrollView {
			Text(content)
				.font(.system(size: fontSize))
				.foregroundColor(.white)
				.padding(.horizontal, 20)
				.padding(.bottom, 20)
		}
	}
}

// MARK: - Settings Panel View
struct SettingsPanelView: View {
	@Binding var fontSize: CGFloat
	@Binding var brightness: Double
	@Binding var selectedFont: String
	let fonts: [String]

	var body: some View {
		VStack(spacing: 0) {
			// Tab bar with options
			ReaderTabBar(selectedTab: "Font")

			// Font selection
			FontSelectionView(
				selectedFont: $selectedFont,
				fonts: fonts
			)

			Divider()
				.background(Color.gray.opacity(0.5))

			// Font size slider
			FontSizeSlider(fontSize: $fontSize)

			// Brightness slider
			BrightnessSlider(brightness: $brightness)
		}
		.background(Color(UIColor.darkGray))
	}
}

// MARK: - Reader Tab Bar
struct ReaderTabBar: View {
	@State var selectedTab: String = "Font"
	let tabs = ["Font", "Layout", "Themes", "More"]

	var body: some View {
		HStack {
			ForEach(tabs, id: \.self) { tab in
				Spacer()

				Text(tab)
					.foregroundColor(tab == selectedTab ? .blue : .white)
					.padding(.vertical, 15)
					.overlay(
						Rectangle()
							.fill(Color.blue)
							.frame(height: 3)
							.offset(y: 1)
							.opacity(tab == selectedTab ? 1 : 0),
						alignment: .bottom
					)
					.onTapGesture {
						selectedTab = tab
					}

				Spacer()
			}
		}
		.background(Color(UIColor.darkGray).opacity(0.3))
	}
}

// MARK: - Font Selection View
struct FontSelectionView: View {
	@Binding var selectedFont: String
	let fonts: [String]

	var body: some View {
		ScrollView(.horizontal, showsIndicators: false) {
			HStack(spacing: 30) {
				ForEach(0..<fonts.count, id: \.self) { index in
					FontOption(
						name: fonts[index],
						isSelected: fonts[index] == selectedFont,
						index: index
					)
					.onTapGesture {
						selectedFont = fonts[index]
					}
				}
			}
			.padding(.horizontal, 20)
		}
		.background(Color(UIColor.darkGray).opacity(0.3))
	}
}

// MARK: - Font Option
struct FontOption: View {
	let name: String
	let isSelected: Bool
	let index: Int

	var body: some View {
		VStack {
			Text("Aa")
				.font(fontStyle(forIndex: index))
				.foregroundColor(isSelected ? .blue : .white)

			Text(name)
				.font(.system(size: 14))
				.multilineTextAlignment(.center)
				.foregroundColor(isSelected ? .blue : .white)
				.lineLimit(2)
				.frame(width: 100)
		}
		.padding(.vertical)
		.overlay(
			Rectangle()
				.fill(Color.blue)
				.frame(height: 2)
				.opacity(isSelected ? 1 : 0),
			alignment: .bottom
		)
	}

	private func fontStyle(forIndex index: Int) -> Font {
		switch index {
		case 0: return .system(size: 40, weight: .bold)
		case 1: return .system(size: 40, weight: .bold, design: .serif)
		case 2: return .system(size: 40)
		default: return .system(size: 40, weight: .bold, design: .serif)
		}
	}
}

// MARK: - Font Size Slider
struct FontSizeSlider: View {
	@Binding var fontSize: CGFloat

	var body: some View {
		HStack {
			Text("A")
				.font(.system(size: 16))
				.foregroundColor(.white)

			Slider(value: $fontSize, in: 12...32, step: 1)
				.accentColor(.blue)

			Text("A")
				.font(.system(size: 30))
				.foregroundColor(.white)
		}
		.padding()
		.background(Color(UIColor.darkGray).opacity(0.3))
	}
}

// MARK: - Brightness Slider
struct BrightnessSlider: View {
	@Binding var brightness: Double

	var body: some View {
		HStack {
			Image(systemName: "sun.min")
				.foregroundColor(.white)

			Slider(value: $brightness, in: 0...1)
				.accentColor(.blue)

			Image(systemName: "sun.max")
				.foregroundColor(.white)
		}
		.padding()
		.background(Color(UIColor.darkGray).opacity(0.3))
	}
}

struct KindleReaderView_Previews: PreviewProvider {
	static var previews: some View {
		KindleReaderView()
	}
}
