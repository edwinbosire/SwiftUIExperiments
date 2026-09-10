//
//  HighlightSampleView.swift
//  UI-Experiments
//
//  Created by Edwin Bosire on 21/03/2025.
//

import Foundation
import SwiftUI

struct HighlightSampleView: View {
	let sampleHTML = htmlString
	let pageId = "life-in-the-uk"
	private var highlightStorage = HighlightStorage()
	@State private var highlights: [Highlight] = []

	var body: some View {
		VStack {
			HighlightableWebView(
				htmlContent: sampleHTML,
				pageIdentifier: pageId,
				highlights: $highlights
			)

			if !highlights.isEmpty {
				Divider()

				VStack(alignment: .leading) {
					HStack {
						Text("Saved Highlights")
							.font(.headline)
							.padding(.horizontal)

						Spacer()

						Button("Reload") {
							Task {
								highlights.removeAll()
								let hl = highlightStorage.getHighlights(for: pageId)
								await MainActor.run {
									highlights = hl
								}
							}

						}
						Button("Remove All") {
							Task {
								for item in highlightStorage.getHighlights(for: pageId) {
									highlightStorage.deleteHighlight(item, for: pageId)
								}
								await MainActor.run {
									highlights.removeAll()
								}
							}

						}

					}
					.padding(.horizontal)

					List {
						ForEach(highlights) { highlight in
							Text(highlight.text)
								.padding(.vertical, 4)
								.onTapGesture {

								}
						}
					}
					.frame(height: 200)
				}
			}
		}
		.navigationTitle("Highlightable Content")
	}
}

struct HighlightSampleView_Previews: PreviewProvider {
	static var previews: some View {
		NavigationStack(root: {
			HighlightSampleView()
		})
	}
}
