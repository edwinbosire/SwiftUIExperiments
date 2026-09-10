//
//  Charts.swift
//  UI-Experiments
//
//  Created by Edwin Bosire on 19/09/2024.
//

import SwiftUI
import Charts

struct Charts: View {
	@State private var isDragging = false
	@State private var selectedDate: (date: Date, uv: Double)?

	var body: some View {
		Chart {
			ForEach(currentUVData, id: \.date) { dataPoint in
				AreaMark(
					x: .value("Time of day", dataPoint.date),
					y: .value("UV index", dataPoint.uv)
				)
				.interpolationMethod(.cardinal)
				.foregroundStyle(
					.linearGradient(
						colors: [.green, .yellow, .red],
						startPoint: .bottom, endPoint: .top
					)
					.opacity(0.5)
				)
				.alignsMarkStylesWithPlotArea()

				LineMark(
					x: .value("Time of day", dataPoint.date),
					y: .value("UV index", dataPoint.uv)
				)
				.interpolationMethod(.cardinal)
				.foregroundStyle(
					.linearGradient(
						colors: [.green, .yellow, .red],
						startPoint: .bottom, endPoint: .top
					)
				)
				.lineStyle(StrokeStyle(lineWidth: 4))
				.alignsMarkStylesWithPlotArea()
			}

			if let selectedDate {
				RuleMark(x: .value("Hover-Now", selectedDate.date))
					.foregroundStyle(Color.secondary.gradient)
					.accessibilityHidden(true)
					.annotation {
						Text("\(selectedDate.uv)")
								.foregroundColor(.secondary)
						}

				PointMark(
					x: .value("Hover-Time of day", selectedDate.date),
					y: .value("Hover-UV index", selectedDate.uv)
				)
				.symbolSize(CGSize(width: 16, height: 16))
				.foregroundStyle(.regularMaterial)
				.accessibilityHidden(true)

				PointMark(
					x: .value("Time of day", selectedDate.date),
					y: .value("UV index", selectedDate.uv)
				)
				.symbolSize(CGSize(width: 6, height: 6))
				.foregroundStyle(Color.primary)
				.accessibilityLabel("Now")
			}
			
			if let dataPoint = closestDataPoint(for: currentDate) {

				if let firstDataPoint = currentUVData.first {
					RectangleMark(
						xStart: .value("", firstDataPoint.date),
						xEnd: .value("", dataPoint.date)
					)

					.foregroundStyle(.thickMaterial)
					.opacity(0.6)
					.accessibilityHidden(true)
					.mask {
						ForEach(currentUVData, id: \.date) { dataPoint in
							AreaMark(
								x: .value("Time of day", dataPoint.date),
								y: .value("UV index", dataPoint.uv),
								series: .value("", "mask"),
								stacking: .unstacked
							)
							.interpolationMethod(.cardinal)

							LineMark(
								x: .value("Time of day", dataPoint.date),
								y: .value("UV index", dataPoint.uv),
								series: .value("", "mask")
							)
							.interpolationMethod(.cardinal)
							.lineStyle(StrokeStyle(lineWidth: 4))
						}
					}
				}

				RuleMark(x: .value("Now", dataPoint.date))
					.foregroundStyle(Color.secondary)
					.accessibilityHidden(true)

				PointMark(
					x: .value("Time of day", dataPoint.date),
					y: .value("UV index", dataPoint.uv)
				)
				.symbolSize(CGSize(width: 16, height: 16))
				.foregroundStyle(.regularMaterial)
				.accessibilityHidden(true)

				PointMark(
					x: .value("Time of day", dataPoint.date),
					y: .value("UV index", dataPoint.uv)
				)
				.symbolSize(CGSize(width: 6, height: 6))
				.foregroundStyle(Color.primary)
				.accessibilityLabel("Now")

			}

		}
		.chartYAxis {
			AxisMarks(
				format: .number,
				preset: .inset,
				values: Array(0...12)
			)

			AxisMarks(
				preset: .inset,
				position: .leading,
				values: [1, 3, 6, 8, 11]
			) { value in
				AxisValueLabel(
					descriptionForUVIndex(value.as(Double.self)!)
				)
			}
		}
		.chartYScale(range: .plotDimension(padding: 2))
		.chartOverlay { chartProxy in
			GeometryReader {geo in
				Color.indigo.opacity(0.3)
					.gesture(
						DragGesture()
							.onChanged { value in
								guard let pFrame = chartProxy.plotFrame else {return}
								let origin = geo[pFrame].origin
								let location = CGPoint(
									x: value.location.x - origin.x,
									y: value.location.y - origin.y)

								isDragging = true
								if let date: Date = chartProxy.value(atX: location.x) {
									selectedDate = closestDataPoint(for: date)
								}
							}
							.onEnded {_ in
								isDragging = false
								selectedDate = nil
							}

					)
			}
		}


	}
}


#Preview {
	Charts()
}

let currentDate = Calendar.date(bySettingHour: 12, of: Date())!

let uvData = [
	(hour: 6, uv: 0), (hour: 8, uv: 1),
	(hour: 10, uv: 4), (hour: 12, uv: 6.5),
	(hour: 14, uv: 8.2), (hour: 16, uv: 6),
	(hour: 18, uv: 1.3), (hour: 20, uv: 0)
]

var currentUVData: [(date: Date, uv: Double)] {
	uvData.map {
		(
			date: Calendar.date(
				bySettingHour: $0.hour, of: currentDate
			)!,
			uv: $0.uv
		)
	}
}

var currentUVDataMap: [Date: Double] = {
	var map = [Date: Double]()
	currentUVData.forEach {
		map[$0.date] = $0.uv
	}
	return map
}()

extension Calendar {
	static func date(bySettingHour hour: Int, of date: Date) -> Date? {
		Calendar.current.date(
			bySettingHour: hour,
			minute: 0,
			second: 0,
			of: date
		)
	}
}

func descriptionForUVIndex(_ index: Double) -> String {
	switch index {
		case 0...2: return "Low"
		case 3...5: return "Moderate"
		case 6...7: return "High"
		case 8...10: return "Very high"
		default: return "Extreme"
	}
}

func closestDataPoint(for date: Date) -> (date: Date, uv: Double)? {
	currentUVData.sorted { a, b in
		abs(date.timeIntervalSince(a.date)) < abs(date.timeIntervalSince(b.date))
	}.first
}
