import SwiftUI

struct ExperimentCatalogueView: View {
    let experiments: [CatalogueExperiment]
    @State private var category = CatalogueCategory.all
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .largeTitle) private var headingSize = 41

    private func columns(for width: CGFloat) -> [GridItem] {
        if dynamicTypeSize.isAccessibilitySize || width < 652 {
            return [GridItem(.flexible())]
        }
        return [GridItem(.adaptive(minimum: 320), spacing: 12)]
    }

    private var featured: CatalogueExperiment? {
        category == .all ? experiments.first : nil
    }

    private var collection: [CatalogueExperiment] {
        experiments.filter {
            (category == .all || $0.category == category) && $0.id != featured?.id
        }
    }

    var body: some View {
        NavigationStack {
          GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    introduction
                    if let featured {
                        NavigationLink {
                            featured.destination()
                        } label: {
                            FeaturedExperimentCard(experiment: featured)
                        }
                        .accessibilityIdentifier(featured.id)
                        .accessibilityLabel("Featured: \(featured.title). \(featured.detail)")
                        .accessibilityHint("Opens the experiment")
                    }
                    catalogue(width: min(880, geometry.size.width) - 48)
                    colophon
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 28)
                .frame(maxWidth: 880)
                .frame(maxWidth: .infinity)
            }
            .accessibilityIdentifier("experiment-catalogue")
            .background(CataloguePalette.paper.ignoresSafeArea())
            .safeAreaInset(edge: .top, spacing: 0) {
                CataloguePalette.paper
                    .frame(height: 1)
                    .background(CataloguePalette.paper.ignoresSafeArea(edges: .top))
            }
            .foregroundStyle(CataloguePalette.ink)
            .buttonStyle(.plain)
            .toolbar(.hidden, for: .navigationBar)
            .navigationTitle("UI Experiments")
          }
        }
        .tint(CataloguePalette.ink)
        .preferredColorScheme(.light)
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 23) {
            HStack(spacing: 9) {
                Image(systemName: "square.stack.3d.up")
                    .font(.system(size: 19, weight: .regular))
                    .accessibilityHidden(true)
                Text("UI EXPERIMENTS")
                    .font(.system(.caption2, design: .monospaced, weight: .medium))
                    .tracking(2)
                Spacer(minLength: 12)
                Image(systemName: "sparkle")
                    .font(.system(size: 21, weight: .light))
                    .foregroundStyle(CataloguePalette.orange)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 12) {
                Text("Small details.\nBig possibilities.")
                    .font(.system(size: headingSize, weight: .regular, design: .serif))
                    .tracking(-1.3)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Text("A collection of playful interfaces.\nPick an experiment. See what happens.")
                    .font(.subheadline)
                    .foregroundStyle(CataloguePalette.muted)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func catalogue(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                Text("The collection")
                    .font(.system(.title2, design: .serif))
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Text("\(category == .all ? experiments.count : collection.count) STUDIES")
                    .font(.system(.caption2, design: .monospaced))
                    .tracking(1.2)
                    .foregroundStyle(CataloguePalette.muted)
                    .accessibilityIdentifier("catalogue-count")
            }
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(CatalogueCategory.allCases) { option in
                        Button {
                            category = option
                        } label: {
                            Text(option.rawValue)
                                .font(.subheadline.weight(category == option ? .medium : .regular))
                                .padding(.horizontal, 19)
                                .frame(minHeight: 44)
                                .background(category == option ? CataloguePalette.ink : .clear, in: Capsule())
                                .foregroundStyle(category == option ? CataloguePalette.paper : CataloguePalette.muted)
                                .overlay {
                                    Capsule().strokeBorder(category == option ? .clear : CataloguePalette.line)
                                }
                        }
                        .accessibilityAddTraits(category == option ? .isSelected : [])
                        .accessibilityIdentifier("catalogue-filter-\(option.rawValue.lowercased())")
                    }
                }
                .padding(.vertical, 1)
            }
            .scrollIndicators(.hidden)
            .accessibilityIdentifier("catalogue-filters")
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Filter experiments")

            LazyVGrid(columns: columns(for: width), spacing: 12) {
                ForEach(collection) { experiment in
                    NavigationLink {
                        experiment.destination()
                    } label: {
                        CatalogueExperimentRow(experiment: experiment)
                    }
                    .accessibilityIdentifier(experiment.id)
                    .accessibilityLabel("\(experiment.title). \(experiment.detail)")
                    .accessibilityHint("Opens the \(experiment.category.rawValue.lowercased()) experiment")
                }
            }
        }
    }

    private var colophon: some View {
        VStack(spacing: 16) {
            Rectangle().fill(CataloguePalette.line).frame(height: 1)
            HStack(spacing: 7) {
                Image(systemName: "curlybraces").accessibilityHidden(true)
                Text("Made with curiosity & SwiftUI")
            }
            .font(.caption)
            .foregroundStyle(CataloguePalette.muted)
            .frame(maxWidth: .infinity)
        }
        .padding(.top, 6)
    }
}

private struct FeaturedExperimentCard: View {
    let experiment: CatalogueExperiment
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Circle().fill(CataloguePalette.orange).frame(width: 5, height: 5)
                Text("IN THE SPOTLIGHT")
                    .font(.system(.caption2, design: .monospaced, weight: .medium))
                    .tracking(1.5)
                Spacer()
                Text("01").font(.system(.caption2, design: .monospaced))
            }
            .foregroundStyle(CataloguePalette.ink)
            .padding(.horizontal, 22)
            .padding(.top, 20)
            CatalogueArtwork(kind: experiment.artwork, isHero: true)
                .frame(height: 170)
                .padding(.horizontal, 20)
                .padding(.top, 2)
                .accessibilityHidden(true)
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(experiment.title).font(.system(.title2, design: .serif))
                    Text(experiment.detail).font(.caption).foregroundStyle(CataloguePalette.muted)
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                if !dynamicTypeSize.isAccessibilitySize {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(CataloguePalette.paper)
                        .frame(width: 42, height: 42)
                        .background(CataloguePalette.ink, in: Circle())
                }
            }
            .foregroundStyle(CataloguePalette.ink)
            .padding(.horizontal, 22)
            .padding(.bottom, 22)
        }
        .background(CataloguePalette.sage.opacity(0.75), in: RoundedRectangle(cornerRadius: 24))
        .overlay { RoundedRectangle(cornerRadius: 24).strokeBorder(CataloguePalette.ink.opacity(0.07)) }
        .contentShape(RoundedRectangle(cornerRadius: 24))
    }
}

private struct CatalogueExperimentRow: View {
    let experiment: CatalogueExperiment
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(spacing: 15) {
            if !dynamicTypeSize.isAccessibilitySize {
                CatalogueArtwork(kind: experiment.artwork)
                    .frame(width: 62, height: 66)
                    .background(experiment.artwork.tint.opacity(0.11), in: RoundedRectangle(cornerRadius: 15))
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 5) {
                Text(experiment.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CataloguePalette.ink)
                Text(experiment.detail)
                    .font(.caption)
                    .foregroundStyle(CataloguePalette.muted)
                    .lineSpacing(2)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "arrow.up.right")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(CataloguePalette.muted)
                .accessibilityHidden(true)
        }
        .padding(13)
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        .background(.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 20))
        .overlay { RoundedRectangle(cornerRadius: 20).strokeBorder(CataloguePalette.ink.opacity(0.07)) }
        .contentShape(RoundedRectangle(cornerRadius: 20))
    }
}
