import SwiftUI

struct CatalogueArtwork: View {
    enum Kind {
        case journey, graph, mascots, owl, traveler, guitar, layout, checkbox, quiz, highlighter, sliders, books, splash

        var symbol: String {
            switch self {
            case .journey: "suitcase.rolling.fill"
            case .graph: "chart.xyaxis.line"
            case .mascots: "eyes"
            case .owl: "bird.fill"
            case .traveler: "figure.hiking"
            case .guitar: "guitars.fill"
            case .layout: "rectangle.3.group.fill"
            case .checkbox: "checkmark.square.fill"
            case .quiz: "checklist"
            case .highlighter: "highlighter"
            case .sliders: "slider.horizontal.3"
            case .books: "books.vertical.fill"
            case .splash: "square.stack.3d.up.fill"
            }
        }

        var tint: Color {
            switch self {
            case .journey, .highlighter, .traveler, .splash: CataloguePalette.orange
            case .graph, .layout, .checkbox: CataloguePalette.ink
            case .mascots, .guitar: Color(red: 0.52, green: 0.40, blue: 0.64)
            case .owl: Color(red: 0.40, green: 0.55, blue: 0.30)
            case .quiz, .sliders: Color(red: 0.27, green: 0.49, blue: 0.53)
            case .books: Color(red: 0.66, green: 0.43, blue: 0.30)
            }
        }
    }

    let kind: Kind
    var isHero = false

    var body: some View {
        if kind == .splash {
            FloatingExperimentArtwork(time: 0)
                .frame(width: isHero ? 170 : 52, height: isHero ? 170 : 52)
        } else if isHero {
            GeometryReader { geometry in
                heroComposition
                    .frame(width: 280, height: 170)
                    .scaleEffect(min(geometry.size.width / 280, geometry.size.height / 170))
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
        } else if kind == .mascots {
            mascot.frame(width: 42, height: 42)
        } else {
            Image(systemName: kind.symbol)
                .font(.system(size: 28, weight: .light))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(kind.tint)
        }
    }

    private var heroComposition: some View {
        ZStack {
            Circle()
                .strokeBorder(CataloguePalette.ink.opacity(0.13), lineWidth: 1)
                .frame(width: 158, height: 158)
                .offset(x: 10, y: -3)
            Circle()
                .fill(CataloguePalette.ink.opacity(0.055))
                .frame(width: 135, height: 135)
                .offset(x: 10, y: -3)
            Ellipse()
                .fill(CataloguePalette.ink.opacity(0.08))
                .frame(width: 183, height: 9)
                .offset(x: 4, y: 68)
            Circle()
                .fill(Color(red: 0.91, green: 0.69, blue: 0.37))
                .frame(width: 28, height: 28)
                .offset(x: 60, y: -43)
            Image(systemName: "sparkle")
                .font(.system(size: 19, weight: .light))
                .foregroundStyle(CataloguePalette.ink.opacity(0.7))
                .offset(x: -100, y: -29)
            Image(systemName: "sparkle")
                .font(.system(size: 12, weight: .light))
                .foregroundStyle(CataloguePalette.orange)
                .offset(x: 104, y: 25)
            RoundedRectangle(cornerRadius: 9)
                .fill(CataloguePalette.ink)
                .frame(width: 49, height: 68)
                .overlay {
                    Image(systemName: "globe.europe.africa")
                        .font(.system(size: 25, weight: .ultraLight))
                        .foregroundStyle(CataloguePalette.sage)
                }
                .rotationEffect(.degrees(-19))
                .offset(x: -63, y: 27)
            if kind == .journey {
                suitcase
                    .rotationEffect(.degrees(-9))
                    .offset(x: -15, y: 7)
                Image(systemName: "airplane")
                    .font(.system(size: 37, weight: .regular))
                    .foregroundStyle(CataloguePalette.ink)
                    .rotationEffect(.degrees(-22))
                    .offset(x: 65, y: -57)
            } else {
                RoundedRectangle(cornerRadius: 22)
                    .fill(kind.tint)
                    .frame(width: 92, height: 102)
                    .overlay {
                        if kind == .mascots {
                            mascot.frame(width: 65, height: 65)
                        } else {
                            Image(systemName: kind.symbol)
                                .font(.system(size: 48, weight: .light))
                                .foregroundStyle(CataloguePalette.paper)
                        }
                    }
                    .rotationEffect(.degrees(-9))
                    .offset(x: -12, y: 2)
            }
            ticket
                .rotationEffect(.degrees(8))
                .offset(x: 46, y: 39)
        }
    }

    private var ticket: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("A LITTLE CURIOSITY")
                .font(.system(size: 6, weight: .medium, design: .monospaced))
                .tracking(0.6)
                .foregroundStyle(CataloguePalette.muted)
            HStack(spacing: 10) {
                Text("GOES A LONG WAY").font(.system(size: 8, weight: .medium, design: .monospaced))
                Image(systemName: "arrow.right").font(.system(size: 9))
            }
            Capsule().fill(CataloguePalette.ink.opacity(0.25)).frame(width: 39, height: 2)
        }
        .foregroundStyle(CataloguePalette.ink)
        .padding(12)
        .frame(width: 139, height: 64, alignment: .leading)
        .background(CataloguePalette.paper, in: RoundedRectangle(cornerRadius: 9))
        .overlay { RoundedRectangle(cornerRadius: 9).strokeBorder(CataloguePalette.ink.opacity(0.13)) }
    }

    private var suitcase: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(CataloguePalette.ink, lineWidth: 4)
                .frame(width: 28, height: 18)
                .offset(y: -47)
            HStack(spacing: 45) {
                Capsule().frame(width: 8, height: 11)
                Capsule().frame(width: 8, height: 11)
            }
            .foregroundStyle(CataloguePalette.ink)
            .offset(y: 48)
            RoundedRectangle(cornerRadius: 15)
                .fill(CataloguePalette.orange)
                .frame(width: 84, height: 96)
                .overlay {
                    RoundedRectangle(cornerRadius: 15)
                        .strokeBorder(CataloguePalette.ink.opacity(0.25), lineWidth: 1.5)
                }
            HStack(spacing: 42) {
                Capsule().frame(width: 3, height: 72)
                Capsule().frame(width: 3, height: 72)
            }
            .foregroundStyle(CataloguePalette.ink.opacity(0.14))
            Circle().fill(Color(red: 1, green: 0.84, blue: 0.57)).frame(width: 20, height: 20)
            VStack(spacing: 28) {
                Rectangle().frame(width: 80, height: 4)
                Rectangle().frame(width: 80, height: 4)
            }
            .foregroundStyle(Color(red: 0.99, green: 0.69, blue: 0.40))
        }
    }

    private var mascot: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(red: 0.70, green: 0.59, blue: 0.82))
                .rotationEffect(.degrees(-8))
            HStack(spacing: 5) {
                ForEach(0..<2) { _ in
                    Capsule().fill(.white).frame(width: 10, height: 16)
                        .overlay(alignment: .trailing) {
                            Capsule().fill(CataloguePalette.ink).frame(width: 4, height: 8).padding(.trailing, 2)
                        }
                }
            }
        }
    }
}
