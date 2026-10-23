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
				NavigationLink {
					XStockGraphDemoView()
				} label: {
					Label("X stock graph", systemImage: "chart.xyaxis.line")
						.font(.title3)
				}
				.accessibilityIdentifier("x-stock-demo")

				NavigationLink {
					GrokBotDemoView()
				} label: {
					Label("Grok Bot mascots", systemImage: "eyes")
						.font(.title3)
				}
				.accessibilityIdentifier("grok-bot-demo")

				NavigationLink {
					UltracodeDemoView()
				} label: {
					Label("Ultracode", systemImage: "guitars.fill")
						.font(.title3)
				}
				.accessibilityIdentifier("ultracode-demo")

				NavigationLink {
					DynamicLayoutDemoView()
				} label: {
					Label("Dynamic layout", systemImage: "rectangle.3.group.fill")
						.font(.title3)
				}
				.accessibilityIdentifier("dynamic-layout-demo")

				NavigationLink {
					AnimatedCheckboxDemoView()
				} label: {
					Label("Animated checkbox", systemImage: "checkmark.square")
						.font(.title3)
				}
				.accessibilityIdentifier("animated-checkbox-demo")

				NavigationLink {
					StickyHeaderQuestionView()
				} label: {
					Label("Quiz Page", systemImage: "checklist")
						.font(.title3)
				}

				NavigationLink {
					HighlightSampleView()
				} label: {
					Label("HTML highlighter", systemImage: "highlighter")
						.font(.title3)
				}

				NavigationLink {
					IntensityPickerDemoView()
				} label: {
					Label("Intensity picker", systemImage: "slider.horizontal.3")
						.font(.title3)
				}

				NavigationLink {
					CoverFlowDemoView()
				} label: {
					Label("Cover Flow", systemImage: "books.vertical")
						.font(.title3)
				}

			}
			.navigationTitle("UI Experiements")
			.navigationBarTitleDisplayMode(.large)
		}

	}
}

#Preview {
    ContentView()
}
