//
//  HighlightableWebView.swift
//  UI-Experiments
//
//  Created by Edwin Bosire on 21/03/2025.
//

import SwiftUI
import WebKit
import Combine

struct HighlightableWebView: UIViewRepresentable {
	let htmlContent: String
	let pageIdentifier: String
	@Binding var highlights: [Highlight]

	func makeUIView(context: Context) -> WKWebView {
		// customized content controller
		let userContentController = WKUserContentController()

		// Add script
		let script = WKUserScript(source: javascript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
		userContentController.addUserScript(script)

		// Setup JavaScript handler
		userContentController.add(context.coordinator, name: "highlightHandler")

		// Add debug handler
		userContentController.add(context.coordinator, name: "errorHandler")

		// Preferences
		let preferences = WKWebpagePreferences()
		preferences.allowsContentJavaScript = true
		preferences.preferredContentMode = .mobile

		let configuration = WKWebViewConfiguration()
		configuration.userContentController = userContentController
		configuration.defaultWebpagePreferences = preferences

		let webView = WKWebView(frame: .zero, configuration: configuration)
		webView.navigationDelegate = context.coordinator
		webView.isInspectable = true
		webView.loadHTMLString(htmlContent, baseURL: nil)

		return webView
	}

	func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.parent = self
        guard context.coordinator.loadedHTML != htmlContent || context.coordinator.loadedPageID != pageIdentifier else { return }
        context.coordinator.loadedHTML = htmlContent
        context.coordinator.loadedPageID = pageIdentifier
        webView.loadHTMLString(htmlContent, baseURL: nil)
    }

    func makeCoordinator() -> Coordinator {
		Coordinator(self)
	}

	class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
		var parent: HighlightableWebView
        var loadedHTML: String
        var loadedPageID: String
		private var highlightStorage = HighlightStorage()

		init(_ parent: HighlightableWebView) {
			self.parent = parent
            loadedHTML = parent.htmlContent
            loadedPageID = parent.pageIdentifier
			super.init()
		}

		// Handle navigation events
		func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
			// Load stored highlights for this page
			let storedHighlights = highlightStorage.getHighlights(for: parent.pageIdentifier)
			parent.highlights = storedHighlights

			// Convert to JSON and apply them
			if let highlightsData = try? JSONEncoder().encode(storedHighlights),
			   let highlightsJSON = String(data: highlightsData, encoding: .utf8) {
				
				let js = "applyStoredHighlights(\(highlightsJSON))"
				webView.evaluateJavaScript(js) { result, error in
					if let error = error {
						print("Error applying highlights: \(error)")
					}

					if let result {
						print("Result: \(result)")
					}
				}
			}
		}

		// Handle messages from JavaScript
		func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
			switch message.name {
				case "errorHandler":
					// You should actually handle the error :)
					print("🚩 \(message.name): \(message.body)")
				case "highlightHandler":
					handleHighlighter()
				default:
					print("Received invalid message: \(message.name)")
			}

			func handleHighlighter() {
				guard let body = message.body as? [String: Any],
					  let action = body["action"] as? String else {
					return
				}

				if action == "addHighlight",
				   let highlightInfo = body["highlight"] as? [String: Any],
				   let id = highlightInfo["id"] as? String,
				   let text = highlightInfo["text"] as? String,
				   let xpath = highlightInfo["xpath"] as? String {

					// Create new highlight
					let highlight = Highlight(
						id: id,
						text: text,
						xpath: xpath,
						pageIdentifier: parent.pageIdentifier
					)

					// Update UI
					DispatchQueue.main.async {
						self.parent.highlights.append(highlight)
						// Save to storage
						self.highlightStorage.saveHighlight(highlight, for: self.parent.pageIdentifier)
					}
				}
			}
		}
	}
}

// Model for a highlight
struct Highlight: Codable, Identifiable, Equatable {
	let id: String
	let text: String
	let xpath: String
	let pageIdentifier: String
}

// Storage service for highlights
class HighlightStorage {
	private let userDefaults = UserDefaults.standard
	private let highlightsKey = "page_highlights_"

	func getHighlights(for pageIdentifier: String) -> [Highlight] {
		let key = highlightsKey + pageIdentifier
		guard let data = userDefaults.data(forKey: key),
			  let highlights = try? JSONDecoder().decode([Highlight].self, from: data) else {
			return []
		}
		return highlights
	}

	func saveHighlight(_ highlight: Highlight, for pageIdentifier: String) {
		let key = highlightsKey + pageIdentifier
		var highlights = getHighlights(for: pageIdentifier)

		// Avoid duplicates
		if !highlights.contains(where: { $0.id == highlight.id }) {
			highlights.append(highlight)

			if let data = try? JSONEncoder().encode(highlights) {
				userDefaults.set(data, forKey: key)
			}
		}
	}

	func deleteHighlight(_ highlight: Highlight, for pageIdentifier: String) {
		let key = highlightsKey + pageIdentifier
		var highlights = getHighlights(for: pageIdentifier)

		highlights.removeAll(where: { $0.id == highlight.id })

		if let data = try? JSONEncoder().encode(highlights) {
			userDefaults.set(data, forKey: key)
		}
	}
}


var javascript: String = {
	guard let fileURL = Bundle.main.url(forResource: "highlight_script", withExtension: "js") else {
		print("☢️ Failed to load highlight_script")

		return ""
	}


	if let script = try? String(contentsOf: fileURL, encoding: .utf8) {
		return script
	}
	print("☢️ Failed to load highlight_script 2")

	return ""
}()

var htmlString: String = {
	guard let fileURL = Bundle.main.url(forResource: "htmlString", withExtension: "html") else {
		print("☢️ Failed to load htmlString")
		return ""
	}


	if let script = try? String(contentsOf: fileURL, encoding: .utf8) {
		return script
	}
	print("☢️ Failed to load htmlString 2")
	return ""
}()
