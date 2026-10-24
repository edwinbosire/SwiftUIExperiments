import SwiftUI

struct HighlightSampleView: View {
    let sampleHTML = htmlString
    let pageId = "life-in-the-uk"
    private var highlightStorage = HighlightStorage()
    @State private var highlights: [Highlight] = []

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                HighlightableWebView(htmlContent: sampleHTML, pageIdentifier: pageId, highlights: $highlights)
                    .frame(minHeight: min(100, geometry.size.height * 0.4))
                    .layoutPriority(1)
                if !highlights.isEmpty {
                    Divider()
                    ScrollView {
                     VStack(alignment: .leading, spacing: 8) {
                        Text("Saved Highlights").font(.headline)
                        HStack {
                            Button("Reload") { highlights = highlightStorage.getHighlights(for: pageId) }
                            Spacer()
                            Button("Remove All") {
                                for highlight in highlightStorage.getHighlights(for: pageId) {
                                    highlightStorage.deleteHighlight(highlight, for: pageId)
                                }
                                highlights.removeAll()
                            }
                        }
                        .font(.subheadline)
                        .frame(minHeight: 44)
                        ForEach(highlights) { highlight in
                            Text(highlight.text)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.vertical, 8)
                            Divider()
                        }
                    }
                    .padding(.horizontal, 16)
                    }
                    .frame(maxHeight: min(300, geometry.size.height * 0.45))
                }
            }
            .frame(maxWidth: 1100)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Highlightable Content")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { HighlightSampleView() }
}
