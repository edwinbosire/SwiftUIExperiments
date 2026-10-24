import SwiftUI

enum CatalogueCategory: String, CaseIterable, Identifiable {
    case all = "All"
    case motion = "Motion"
    case controls = "Controls"
    case layouts = "Layouts"

    var id: String { rawValue }
}

struct CatalogueExperiment: Identifiable {
    let id: String
    let title: String
    let detail: String
    let category: CatalogueCategory
    let artwork: CatalogueArtwork.Kind
    // Create each destination only when its link is followed.
    let destination: () -> AnyView

    init<Destination: View>(id: String, title: String, detail: String,
                            category: CatalogueCategory, artwork: CatalogueArtwork.Kind,
                            @ViewBuilder destination: @escaping () -> Destination) {
        self.id = id
        self.title = title
        self.detail = detail
        self.category = category
        self.artwork = artwork
        self.destination = { AnyView(destination()) }
    }
}

enum CataloguePalette {
    static let paper = Color(red: 0.97, green: 0.96, blue: 0.93)
    static let ink = Color(red: 0.12, green: 0.27, blue: 0.22)
    static let muted = Color(red: 0.36, green: 0.42, blue: 0.36)
    static let sage = Color(red: 0.88, green: 0.91, blue: 0.83)
    static let line = ink.opacity(0.12)
    static let orange = Color(red: 0.87, green: 0.43, blue: 0.25)
}
