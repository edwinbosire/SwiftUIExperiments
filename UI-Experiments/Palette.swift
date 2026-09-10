//
//  Palette.swift
//  UI-Experiments
//
//  Created by Edwin Bosire on 04/03/2025.
//

import SwiftUI

struct Palette: View {
	var body: some View {
		ScrollView {
			VStack(spacing: 0.0) {
				Pallette()
				Monochromatic()
				BasePalette()
			}
		}
		.background(Color(hex: "2A9D8F").darken)
	}

}

struct Pallette: View {
	let palette: [String] = [
		"264653",
		"2A9D8F",
		"E9C46A",
		"F4A261",
		"E76F51"]

	var body: some View {
		VStack(alignment: .leading, spacing: 0.0) {
			Group {
				Text("Palette")
					.font(.title)
					.fontWeight(.bold)
					.foregroundStyle(Color.white.darken)
					.padding(.leading)

				Text("Cool colors are generally associated with peace, serenity or calmness. These include shades of green, blue and purple")
					.foregroundStyle(Color.white.darken(by:0.2))
					.padding(.leading)
					.padding(.bottom)
			}


			HStack(spacing: 0.0) {
				ForEach(0...9, id: \.self) { value in
					Rectangle()
						.fill(Color.white.darken(by: 0.8))
						.overlay {
							Text("\(value*10)%")
								.font(.caption2)
								.foregroundStyle(Color.white.darken(by: 0.2))
						}

				}
			}
			.frame(height: 20.0)
			VStack(spacing: 0.0) {
				ForEach(palette, id: \.self) { colorCode in
					HStack(spacing: 0.0){
						ForEach(0..<9, id: \.self) { value in
							Rectangle()
								.fill(Color(hex: colorCode)
									.darken(by: normalize(value: Double(value))))
						}
					}
					.frame(height: 44.0)
				}

			}
		}
		.background(Color.clear)

	}
}

struct Monochromatic: View {
	let neutralTones: [Color] = [.blue, .green, .purple]

	var body: some View {
		VStack(alignment: .leading) {
			Text("Monochromatic")
				.font(.title)
				.fontWeight(.bold)
				.foregroundStyle(Color.white.darken(by:0.1))

			Text("A monochromatic color is created when we use one strong color with multiple variations of that one color")
				.foregroundStyle(Color.white.darken(by:0.2))

			VStack(spacing: 10.0) {
				ForEach(neutralTones, id: \.self) { color in
					HStack(spacing: 10.0) {
						RoundedRectangle(cornerRadius: 8.0)
							.fill(color.darken)
							.overlay {
								RoundedRectangle(cornerRadius: 8.0)
									.fill(color.lighten)
									.offset(y: -4.0)

							}
							.overlay {
								Text("\(color)")
									.foregroundColor(.white)
									.fontWeight(.bold)
							}
							.clipShape(RoundedRectangle(cornerRadius: 8.0))


						RoundedRectangle(cornerRadius: 8.0)
							.fill(color)
							.overlay {
								Text("\(color)")
									.foregroundColor(.white)
									.fontWeight(.bold)
							}

						RoundedRectangle(cornerRadius: 8.0)
							.fill(color)
							.overlay {
								RoundedRectangle(cornerRadius: 8.0)
									.fill(color.darken)
									.offset(y: -4)

							}
							.overlay {
								Text("\(color)")
									.foregroundColor(.white)
									.fontWeight(.bold)
							}


					}
					.frame(height: 50.0)
				}
			}
		}
		.padding()
		.background(Color.black.lighten(by:0.2))

	}
}
struct BasePalette: View {
	var body: some View {
		VStack(alignment: .leading) {
			Text("Base")
				.font(.title)
				.fontWeight(.bold)
				.foregroundStyle(Color.black.lighten(by: 0.2))
				.padding(.horizontal)

			HStack(spacing: 0.0) {
				ForEach(0..<9, id: \.self) { value in
					VStack(spacing: 0.0) {
						Rectangle()
							.fill(Color.black.lighten(by: norm(value)))
						Rectangle()
							.fill(Color.white.darken(by: norm(value)))

					}
				}

			}

		}
		.background(Color.purple.lighten(by: 0.8))
		.frame(height: 200)

	}
	let min = 0.0
	let max = 9.0
	func norm(_ value: Int) -> Double {
		return normalize(value: Double(value), min: min, max: max)
	}

}

func normalize(value: Double, min: Double = 0, max: Double = 9) -> Double {
	return Double((value - min) / (max - min))
}

#Preview {
	Palette()
}

extension Color {
	func darken(by percentage: Double) -> Color {
		let uiColor = UIColor(self)
		var red: CGFloat = 0
		var green: CGFloat = 0
		var blue: CGFloat = 0
		var alpha: CGFloat = 0

		uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

		// Multiply each component by (1 - percentage) to add black
		return Color(
			red: red * (1 - percentage),
			green: green * (1 - percentage),
			blue: blue * (1 - percentage)
		)
	}
	var darken: Color {
		self.darken(by: 0.2)
	}

	var lighten: Color {
		self.lighten(by: 0.2)
	}

	func lighten(by percentage: Double) -> Color {
		let uiColor = UIColor(self)
		var red: CGFloat = 0
		var green: CGFloat = 0
		var blue: CGFloat = 0
		var alpha: CGFloat = 0

		uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

		// Add white by moving each component toward 1.0 by the given percentage
		return Color(
			red: red + ((1 - red) * percentage),
			green: green + ((1 - green) * percentage),
			blue: blue + ((1 - blue) * percentage)
		)
	}

}
