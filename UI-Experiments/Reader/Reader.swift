import Foundation
import SwiftUI
import WebKit
import Combine

// Model for storing highlights
struct TextHighlight: Codable, Identifiable {
	var id = UUID()
	var chapterId: String
	var highlightId: String
	var text: String
	var startOffset: Int
	var endOffset: Int
	var color: String
	var timestamp: Date
}

// ViewModel to manage highlights
class HighlightManager: ObservableObject {
	@Published var highlights: [TextHighlight] = []
	private let saveKey = "savedHighlights"

	init() {
		loadHighlights()
	}

	func addHighlight(_ highlight: TextHighlight) {
		highlights.append(highlight)
		saveHighlights()
	}

	func removeHighlight(id: String) {
		highlights.removeAll { $0.highlightId == id }
		saveHighlights()
	}

	func getHighlightsForChapter(chapterId: String) -> [TextHighlight] {
		return highlights.filter { $0.chapterId == chapterId }
	}

	private func saveHighlights() {
		if let encoded = try? JSONEncoder().encode(highlights) {
			UserDefaults.standard.set(encoded, forKey: saveKey)
		}
	}

	private func loadHighlights() {
		if let savedHighlights = UserDefaults.standard.data(forKey: saveKey),
		   let decodedHighlights = try? JSONDecoder().decode([TextHighlight].self, from: savedHighlights) {
			highlights = decodedHighlights
		}
	}
}

// WKWebView coordinator to handle JavaScript communication
class WebViewCoordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
	var parent: ReaderWebView

	init(_ parent: ReaderWebView) {
		self.parent = parent
	}

	func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
		if message.name == "highlightHandler" {
			guard let dict = message.body as? [String: Any],
				  let type = dict["type"] as? String else {
				return
			}

			if type == "addHighlight" {
				guard let highlightId = dict["highlightId"] as? String,
					  let text = dict["text"] as? String,
					  let startOffset = dict["startOffset"] as? Int,
					  let endOffset = dict["endOffset"] as? Int,
					  let color = dict["color"] as? String else {
					return
				}

				let highlight = TextHighlight(
					chapterId: parent.chapterId,
					highlightId: highlightId,
					text: text,
					startOffset: startOffset,
					endOffset: endOffset,
					color: color,
					timestamp: Date()
				)

				parent.highlightManager.addHighlight(highlight)
			} else if type == "removeHighlight" {
				if let highlightId = dict["highlightId"] as? String {
					parent.highlightManager.removeHighlight(id: highlightId)
				}
			}
		}
	}

	func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
		// Apply saved highlights after page loads
		let highlights = parent.highlightManager.getHighlightsForChapter(chapterId: parent.chapterId)

		if !highlights.isEmpty {
			// Convert highlights to JSON string
			if let highlightsData = try? JSONEncoder().encode(highlights),
			   let highlightsString = String(data: highlightsData, encoding: .utf8) {
				// Escape quotes for JavaScript
				let escapedHighlights = highlightsString.replacingOccurrences(of: "\"", with: "\\\"")

				// Apply highlights using JavaScript
				let script = "applyHighlights(\"\(escapedHighlights)\");"
				webView.evaluateJavaScript(script, completionHandler: nil)
			}
		}
	}
}

// Enhanced WebView with highlighting capabilities
struct ReaderWebView: UIViewRepresentable {
	var content: String
	var chapterId: String
	@Binding var fontSize: CGFloat
	@ObservedObject var highlightManager: HighlightManager

	func makeCoordinator() -> WebViewCoordinator {
		WebViewCoordinator(self)
	}

	func makeUIView(context: Context) -> WKWebView {
		// Create a user content controller
		let userContentController = WKUserContentController()
		userContentController.add(context.coordinator, name: "highlightHandler")

		// Create configuration with user content controller
		let configuration = WKWebViewConfiguration()
		configuration.userContentController = userContentController
		configuration.defaultWebpagePreferences.allowsContentJavaScript = true

		// Create WKWebView with configuration
		let webView = WKWebView(frame: .zero, configuration: configuration)
		webView.navigationDelegate = context.coordinator
		webView.backgroundColor = .white
		webView.isOpaque = false
		webView.scrollView.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

		return webView
	}

	func updateUIView(_ webView: WKWebView, context: Context) {
		// Create HTML with SF font styling, content, and highlighting JavaScript
		let styledHTML = formatHTML(content: content, fontSize: fontSize)
		webView.loadHTMLString(styledHTML, baseURL: nil)
	}

	// Format HTML with SF Font, readable styling, and highlighting JavaScript
	private func formatHTML(content: String, fontSize: CGFloat) -> String {
		let baseSize = Int(fontSize)
		let css = """
		<style>
			:root {
				color-scheme: light;
			}
			
			body {
				font-family: -apple-system, BlinkMacSystemFont, 'SF Pro', 'SF Pro Text', 'San Francisco', system-ui, sans-serif;
				font-size: \(baseSize)px;
				line-height: 1.5;
				color: rgba(0, 0, 0, 0.85);
				margin: 0;
				padding: 16px 0;
				-webkit-user-select: text;
				-webkit-touch-callout: none;

			}
			
			h1 {
				font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', 'SF Pro', system-ui, sans-serif;
				font-size: \(baseSize + 8)px;
				font-weight: bold;
				margin-bottom: 12px;
			}
			
			h2 {
				font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', 'SF Pro', system-ui, sans-serif;
				font-size: \(baseSize + 4)px;
				font-weight: 600;
				margin-top: 24px;
				margin-bottom: 8px;
			}
			
			p {
				margin-bottom: 16px;
			}
			
			ul {
				padding-left: 24px;
				margin-bottom: 16px;
			}
			
			li {
				margin-bottom: 8px;
			}
			
			blockquote {
				margin: 16px 0;
				padding: 12px 16px;
				background-color: rgba(0, 0, 0, 0.05);
				border-left: 4px solid rgba(0, 0, 0, 0.1);
				font-style: italic;
			}
			
			a {
				color: #007AFF;
				text-decoration: none;
			}
			
			img {
				max-width: 100%;
				height: auto;
				border-radius: 4px;
			}
			
			/* Highlight styles */
			.highlighted {
				border-radius: 2px;
				padding: 0 1px;
				margin: 0 -1px;
			}
			
			.highlight-yellow {
				background-color: rgba(255, 235, 59, 0.5);
			}
			
			.highlight-green {
				background-color: rgba(76, 175, 80, 0.3);
			}
			
			.highlight-blue {
				background-color: rgba(33, 150, 243, 0.3);
			}
			
			.highlight-pink {
				background-color: rgba(233, 30, 99, 0.3);
			}
			
			/* Highlight context menu */
			.highlight-menu {
				position: absolute;
				background-color: #ffffff;
				border-radius: 8px;
				box-shadow: 0 2px 10px rgba(0, 0, 0, 0.2);
				padding: 8px;
				display: flex;
				z-index: 1000;
			}
			
			.highlight-menu button {
				width: 24px;
				height: 24px;
				border-radius: 12px;
				border: 1px solid rgba(0, 0, 0, 0.1);
				margin: 0 4px;
				cursor: pointer;
			}
			
			.highlight-menu .yellow {
				background-color: #FFEB3B;
			}
			
			.highlight-menu .green {
				background-color: #4CAF50;
			}
			
			.highlight-menu .blue {
				background-color: #2196F3;
			}
			
			.highlight-menu .pink {
				background-color: #E91E63;
			}
			
			.highlight-menu .remove {
				background-color: #ffffff;
				color: #FF5722;
				font-weight: bold;
				font-size: 16px;
				display: flex;
				align-items: center;
				justify-content: center;
			}
			
			/* Dark mode support */
			@media (prefers-color-scheme: dark) {
				:root {
					color-scheme: dark;
				}
				
				body {
					background-color: #1a1a1a;
					color: rgba(255, 255, 255, 0.9);
				}
				
				blockquote {
					background-color: rgba(255, 255, 255, 0.1);
					border-left-color: rgba(255, 255, 255, 0.2);
				}
				
				a {
					color: #0A84FF;
				}
				
				.highlight-menu {
					background-color: #333;
					box-shadow: 0 2px 10px rgba(0, 0, 0, 0.5);
				}
				
				.highlight-menu .remove {
					background-color: #333;
				}
				
				/* Adjust highlight colors for dark mode */
				.highlight-yellow {
					background-color: rgba(255, 235, 59, 0.4);
				}
				
				.highlight-green {
					background-color: rgba(76, 175, 80, 0.25);
				}
				
				.highlight-blue {
					background-color: rgba(33, 150, 243, 0.25);
				}
				
				.highlight-pink {
					background-color: rgba(233, 30, 99, 0.25);
				}
			}
		</style>
		"""

		// JavaScript for handling text selection and highlighting
		let javascript = """
		<script>
			// Track if a highlight is in progress to avoid double processing
			let isHighlightInProgress = false;
			
			// Generate a unique ID for each highlight
			function generateUUID() {
				return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
					let r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
					return v.toString(16);
				});
			}
			
			// Create a highlight menu
			function createHighlightMenu() {
				const menu = document.createElement('div');
				menu.className = 'highlight-menu';
				menu.id = 'highlightMenu';
				
				// Create color buttons
				const colors = [
					{ class: 'yellow', name: 'yellow' },
					{ class: 'green', name: 'green' },
					{ class: 'blue', name: 'blue' },
					{ class: 'pink', name: 'pink' }
				];
				
				colors.forEach(color => {
					const button = document.createElement('button');
					button.className = color.class;
					button.onclick = function() { highlightSelection(color.name); };
					menu.appendChild(button);
				});
				
				return menu;
			}
			
			// Position the highlight menu near the selection
			function positionHighlightMenu(selection) {
				const menu = document.getElementById('highlightMenu');
				if (!menu) return;
				
				const range = selection.getRangeAt(0);
				const rect = range.getBoundingClientRect();
				
				// Position above the selection
				menu.style.top = (window.scrollY + rect.top - menu.offsetHeight - 10) + 'px';
				menu.style.left = (window.scrollX + rect.left + (rect.width / 2) - (menu.offsetWidth / 2)) + 'px';
				
				// Make sure the menu is visible
				document.body.appendChild(menu);
			}
			
			// Remove the highlight menu
			function removeHighlightMenu() {
				const menu = document.getElementById('highlightMenu');
				if (menu && menu.parentNode) {
					menu.parentNode.removeChild(menu);
				}
			}
			
			// Create a span with highlight styling
			function createHighlightSpan(color, id) {
				const span = document.createElement('span');
				span.className = 'highlighted highlight-' + color;
				span.setAttribute('data-highlight-id', id);
				return span;
			}
			
			// Highlight the selected text
			function highlightSelection(color) {
				if (isHighlightInProgress) return;
				isHighlightInProgress = true;
				
				const selection = window.getSelection();
				if (selection.rangeCount === 0) {
					isHighlightInProgress = false;
					return;
				}
				
				const range = selection.getRangeAt(0);
				if (range.collapsed) {
					isHighlightInProgress = false;
					return;
				}
				
				// Create a unique ID for this highlight
				const highlightId = generateUUID();
				
				// Create a highlighted span
				const highlightSpan = createHighlightSpan(color, highlightId);
				
				// Apply the highlight
				range.surroundContents(highlightSpan);
				
				// Get the highlighted text
				const text = highlightSpan.textContent;
				
				// Calculate text offsets (for future reference)
				const bodyText = document.body.textContent;
				const startOffset = bodyText.indexOf(text);
				const endOffset = startOffset + text.length;
				
				// Send highlight data to Swift
				window.webkit.messageHandlers.highlightHandler.postMessage({
					type: 'addHighlight',
					highlightId: highlightId,
					text: text,
					startOffset: startOffset,
					endOffset: endOffset,
					color: color
				});
				
				// Clean up
				removeHighlightMenu();
				selection.removeAllRanges();
				isHighlightInProgress = false;
				
				// Add context menu for this highlight
				highlightSpan.addEventListener('contextmenu', function(e) {
					e.preventDefault();
					showHighlightContextMenu(e, highlightId);
					return false;
				});
			}
			
			// Show context menu for existing highlight
			function showHighlightContextMenu(event, highlightId) {
				// Create a context menu for removing highlights
				const contextMenu = document.createElement('div');
				contextMenu.className = 'highlight-menu';
				contextMenu.id = 'contextMenu';
				
				// Add remove button
				const removeButton = document.createElement('button');
				removeButton.className = 'remove';
				removeButton.innerHTML = '×';
				removeButton.onclick = function() { removeHighlight(highlightId); };
				contextMenu.appendChild(removeButton);
				
				// Position the menu at the click location
				contextMenu.style.top = (window.scrollY + event.clientY - 40) + 'px';
				contextMenu.style.left = (window.scrollX + event.clientX - 15) + 'px';
				
				// Add to document
				document.body.appendChild(contextMenu);
				
				// Close the context menu when clicking elsewhere
				setTimeout(() => {
					document.addEventListener('click', function closeMenu(e) {
						if (!contextMenu.contains(e.target)) {
							document.body.removeChild(contextMenu);
							document.removeEventListener('click', closeMenu);
						}
					});
				}, 10);
			}
			
			// Remove a highlight
			function removeHighlight(highlightId) {
				const highlightSpan = document.querySelector(`[data-highlight-id="${highlightId}"]`);
				if (highlightSpan) {
					// Replace the span with its text content
					const parent = highlightSpan.parentNode;
					const text = document.createTextNode(highlightSpan.textContent);
					parent.replaceChild(text, highlightSpan);
					
					// Notify Swift
					window.webkit.messageHandlers.highlightHandler.postMessage({
						type: 'removeHighlight',
						highlightId: highlightId
					});
					
					// Remove any open context menu
					const contextMenu = document.getElementById('contextMenu');
					if (contextMenu) {
						contextMenu.parentNode.removeChild(contextMenu);
					}
				}
			}
			
			// Apply saved highlights
			function applyHighlights(highlightsJSON) {
				const highlights = JSON.parse(highlightsJSON);
				
				for (const highlight of highlights) {
					try {
						// Find occurrence of this highlight text in the document
						const textNodes = [];
						const walker = document.createTreeWalker(
							document.body,
							NodeFilter.SHOW_TEXT,
							null,
							false
						);
						
						let node;
						while (node = walker.nextNode()) {
							const content = node.textContent;
							if (content.includes(highlight.text)) {
								textNodes.push(node);
							}
						}
						
						// Find the right text node with the closest offset to our saved highlight
						if (textNodes.length > 0) {
							// Get body text to match offsets
							const bodyText = document.body.textContent;
							let closestNode = textNodes[0];
							let minDistance = Number.MAX_SAFE_INTEGER;
							
							for (const node of textNodes) {
								const nodeText = node.textContent;
								const nodeStart = bodyText.indexOf(nodeText);
								const distance = Math.abs(nodeStart - highlight.startOffset);
								
								if (distance < minDistance) {
									minDistance = distance;
									closestNode = node;
								}
							}
							
							// Find the position of the highlight text in the node
							const nodeText = closestNode.textContent;
							const index = nodeText.indexOf(highlight.text);
							
							if (index !== -1) {
								// Create a range for this text
								const range = document.createRange();
								range.setStart(closestNode, index);
								range.setEnd(closestNode, index + highlight.text.length);
								
								// Create a highlight span
								const highlightSpan = createHighlightSpan(highlight.color, highlight.highlightId);
								
								// Apply the highlight
								range.surroundContents(highlightSpan);
								
								// Add context menu for this highlight
								highlightSpan.addEventListener('contextmenu', function(e) {
									e.preventDefault();
									showHighlightContextMenu(e, highlight.highlightId);
									return false;
								});
							}
						}
					} catch (error) {
						console.error('Error applying highlight:', error);
					}
				}
			}
			
			// Set up text selection handling
			document.addEventListener('selectionchange', function() {
				// Remove any existing highlight menu
				removeHighlightMenu();
				
				const selection = window.getSelection();
				if (selection.rangeCount === 0 || selection.toString().trim() === '') {
					return;
				}
				
				// Check if selection is inside an existing highlight
				const anchorNode = selection.anchorNode;
				if (anchorNode && anchorNode.parentNode) {
					const parent = anchorNode.parentNode;
					if (parent.classList && parent.classList.contains('highlighted')) {
						return; // Don't show highlight menu for existing highlights
					}
				}
				
				// Only show menu if text is selected
				if (!selection.isCollapsed && selection.toString().trim() !== '') {
					// Create and position the highlight menu
					const menu = createHighlightMenu();
					document.body.appendChild(menu);
					positionHighlightMenu(selection);
				}
			});
			
			// Hide the highlight menu when clicking elsewhere
			document.addEventListener('click', function(e) {
				const menu = document.getElementById('highlightMenu');
				if (menu && !menu.contains(e.target)) {
					removeHighlightMenu();
				}
			});
		  document.addEventListener('touchstart', function(e) {
			  // This prevents the native selection menu from appearing
			  document.documentElement.style.webkitUserSelect = 'none';
			  document.documentElement.style.webkitTouchCallout = 'none';
		  }, false);

		  document.addEventListener('touchend', function(e) {
			  // Re-enable text selection after the touch ends
			  document.documentElement.style.webkitUserSelect = 'text';
			  document.documentElement.style.webkitTouchCallout = 'default';
			  
			  // Small delay to allow our custom selection to work
			  setTimeout(function() {
				  const selection = window.getSelection();
				  if (!selection.isCollapsed && selection.toString().trim() !== '') {
					  // Create and position our custom menu
					  const menu = createHighlightMenu();
					  document.body.appendChild(menu);
					  positionHighlightMenu(selection);
					  
					  // Prevent default context menu
					  e.preventDefault();
					  return false;
				  }
			  }, 100);
		  }, false);
		</script>
		"""

		return """
		<!DOCTYPE html>
		<html>
		<head>
			<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
			<meta charset="UTF-8">
			\(css)
		</head>
		<body>
			\(content)
			\(javascript)
		</body>
		</html>
		"""
	}
}

struct ReaderSampleApp: View {
	@State private var fontSize: CGFloat = 16
	@State private var currentChapter = "Chapter 1"
	@State private var showMenu = false
	@StateObject private var highlightManager = HighlightManager()

	// Sample content
	let sampleContent = """
	<h1>The values and principles of the UK</h1>
	
	<p>British society is founded on fundamental values and principles which all those living in the UK should respect and support. These values are reflected in the responsibilities, rights and privileges of being a British citizen or permanent resident of the UK. They are based on history and traditions and are protected by law, customs and expectations. There is no place in British society for extremism or intolerance.</p>
	
	<p>The fundamental principles of British life include:</p>
	
	<ul>
		<li>Democracy</li>
		<li>The Rule Of Law</li>
		<li>Individual Liberty</li>
		<li>Tolerance Of Those With Different Faiths And Beliefs</li>
		<li>Participation In Community Life</li>
	</ul>
	
	<p>As part of the citizenship ceremony, new citizens pledge to uphold these values. The pledge is:</p>
	
	<blockquote>'I will give my loyalty to the United Kingdom and respect its rights and freedoms. I will uphold its democratic values. I will observe its laws faithfully and fulfil my duties and obligations as a British citizen.'</blockquote>
	
	<p>Flowing from the fundamental principles are responsibilities and freedoms which are shared by all those living in the UK and which we expect all residents to respect.</p>
	
	<p>If you wish to be a permanent resident or citizen of the UK, you should:</p>
	
	<ul>
		<li>Respect And Obey The Law</li>
		<li>Respect The Rights Of Others, Including Their Right To Their Own Opinions</li>
		<li>Treat Others With Fairness</li>
		<li>Look After Yourself And Your Family</li>
		<li>Look After The Area In Which You Live And The Environment</li>
	</ul>
	
	<p>In return, the UK offers:</p>
	
	<ul>
		<li>Freedom Of Belief And Religion</li>
		<li>Freedom Of Speech</li>
		<li>Freedom From Unfair Discrimination</li>
		<li>A Right To A Fair Trial</li>
		<li>A Right To Join In The Election Of A Government</li>
	</ul>
	"""

	var body: some View {
		ZStack {
			// Main background
			Color(red: 0.08, green: 0.25, blue: 0.20)
				.edgesIgnoringSafeArea(.all)

			VStack(spacing: 0) {
				// Custom Navigation Bar

				// Highlighting instructions
				VStack {
					Text("Select text to highlight it")
						.font(.system(size: 12))
						.foregroundColor(.white)
						.padding(.vertical, 4)
				}
				.frame(maxWidth: .infinity)
				.background(Color(red: 0.1, green: 0.3, blue: 0.25))

				// WebView for content with highlighting
//				ReaderWebView(
//					content: sampleContent,
//					chapterId: "chapter-1",
//					fontSize: $fontSize,
//					highlightManager: highlightManager
//				)
//				.background(Color.white)
			}
		}
	}
}

//// Enhanced Side Menu View that can show highlights
//struct SideMenuView: View {
//	@Binding var showMenu: Bool
//	@ObservedObject var highlightManager: HighlightManager
//	@Binding var currentChapter: String
//	@State private var selectedTab = 0
//
//	var body: some View {
//		ZStack {
//			// Semi-transparent overlay
//			Color.black.opacity(0.3)
//				.edgesIgnoringSafeArea(.all)
//				.onTapGesture {
//					withAnimation {
//						showMenu = false
//					}
//				}
//
//			// Menu content
//			HStack {
//				Spacer()
//
//				VStack(alignment: .leading, spacing: 0) {
//					HStack {
//						Spacer()
//						Button(action: {
//							withAnimation {
//								showMenu = false
//							}
//						}) {
//							Image(systemName: "xmark")
//								.foregroundColor(.gray)
//			}
//
//			Text(highlight.text)
//				.font(.system(size: 14))
//				.foregroundColor(.black)
//				.lineLimit(3)
//				.padding(.leading, 8)
//				.padding(.top, 2)
//
//			Divider()
//				.padding(.top, 4)
//		}
//		.padding(.vertical, 4)
//		.contentShape(Rectangle())
//		.onTapGesture {
//			// Here you would add code to navigate to this highlight in the content
//			print("Navigate to highlight: \(highlight.highlightId)")
//		}
//								.padding()
//						}
//					}
//
//					// Tab selector
//					HStack {
//						Button(action: { selectedTab = 0 }) {
//							Text("Contents")
//								.font(.headline)
//								.padding(.vertical, 10)
//								.padding(.horizontal)
//								.foregroundColor(selectedTab == 0 ? .blue : .gray)
//						}
//
//						Button(action: { selectedTab = 1 }) {
//							Text("Highlights")
//								.font(.headline)
//								.padding(.vertical, 10)
//								.padding(.horizontal)
//								.foregroundColor(selectedTab == 1 ? .blue : .gray)
//						}
//					}
//					.padding(.horizontal)
//
//					Divider()
//
//					// Contents tab
//					if selectedTab == 0 {
//						ScrollView {
//							VStack(alignment: .leading, spacing: 15) {
//								MenuItemView(title: "1. The values and principles of the UK", isSelected: currentChapter == "Chapter 1")
//								MenuItemView(title: "2. What is the UK", isSelected: currentChapter == "Chapter 2")
//								MenuItemView(title: "3. A long and illustrious history", isSelected: currentChapter == "Chapter 3")
//								MenuItemView(title: "4. A modern, thriving society", isSelected: currentChapter == "Chapter 4")
//								MenuItemView(title: "5. The UK Government, the law and your role", isSelected: currentChapter == "Chapter 5")
//								MenuItemView(title: "6. Summary", isSelected: currentChapter == "Chapter 6")
//							}
//							.padding(.horizontal)
//							.padding(.vertical, 10)
//						}
//					}
//					// Highlights tab
//					else {
//						ScrollView {
//							VStack(alignment: .leading, spacing: 15) {
//								ForEach(highlightManager.highlights) { highlight in
//									HighlightItemView(highlight: highlight)
//								}
//
//								if highlightManager.highlights.isEmpty {
//									Text("No highlights yet")
//										.foregroundColor(.gray)
//										.italic()
//										.padding(.top, 20)
//										.frame(maxWidth: .infinity, alignment: .center)
//								}
//							}
//							.padding(.horizontal)
//							.padding(.vertical, 10)
//						}
//					}
//				}
//				.background(Color.white)
//				.frame(width: UIScreen.main.bounds.width * 0.8)
//				.edgesIgnoringSafeArea(.vertical)
//			}
//		}
//	}
//}

// View for displaying a highlight in the sidebar
struct HighlightItemView: View {
	let highlight: TextHighlight

	var chapterTitle: String {
		switch highlight.chapterId {
			case "chapter-1": return "Chapter 1"
			case "chapter-2": return "Chapter 2"
			case "chapter-3": return "Chapter 3"
			case "chapter-4": return "Chapter 4"
			case "chapter-5": return "Chapter 5"
			case "chapter-6": return "Chapter 6"
			default: return "Unknown Chapter"
		}
	}

	// Format date to a readable string
	private func formattedDate(_ date: Date) -> String {
		let formatter = DateFormatter()
		formatter.dateStyle = .short
		formatter.timeStyle = .short
		return formatter.string(from: date)
	}

	// Convert string color to SwiftUI Color
	private func colorForHighlight(_ colorString: String) -> Color {
		switch colorString {
			case "yellow": return Color(red: 1.0, green: 0.92, blue: 0.23)
			case "green": return Color(red: 0.3, green: 0.69, blue: 0.31)
			case "blue": return Color(red: 0.13, green: 0.59, blue: 0.95)
			case "pink": return Color(red: 0.91, green: 0.12, blue: 0.39)
			default: return Color.gray
		}
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 4) {
			HStack {
				// Color indicator
				RoundedRectangle(cornerRadius: 2)
					.fill(colorForHighlight(highlight.color))
					.frame(width: 4, height: 16)

				Text(chapterTitle)
					.font(.system(size: 12))
					.foregroundColor(.gray)

				Spacer()

				Text(formattedDate(highlight.timestamp))
					.font(.system(size: 10))
					.foregroundColor(.gray)
			}
		}
	}
}

#Preview {
	ReaderSampleApp()
}
