import SwiftUI
import Charts

/// The stock card and chart interactions from main-3.mp4.
struct XStockGraphDemoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader { geometry in
            let width = min(geometry.size.width, 600)
            let scale = width / 393

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    searchHeader(scale: scale)
                    searchTabs(scale: scale)
                    XStockCard(scale: scale)
                    referencePost(scale: scale)
                }
                .frame(width: width)
                .frame(maxWidth: .infinity)
            }
            .background(.black)
        }
        .background(.black)
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
    }

    private func searchHeader(scale: CGFloat) -> some View {
        HStack(spacing: 8 * scale) {
            Button { dismiss() } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 19 * scale, weight: .regular))
                    .frame(width: 28 * scale, height: 44 * scale)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back to experiments")
            .accessibilityIdentifier("close-x-stock-demo")

            HStack(spacing: 5 * scale) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14 * scale, weight: .semibold))
                    .foregroundStyle(XStockStyle.secondary)
                Text("$NVDA")
                    .font(.system(size: 16 * scale))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 36 * scale)
            .background(Color(white: 0.12), in: Capsule())
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Search results for NVDA")

            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 19 * scale))
                .frame(width: 32 * scale, height: 44 * scale)
                .accessibilityHidden(true)
        }
        .foregroundStyle(XStockStyle.primary)
        .padding(.horizontal, 10 * scale)
        .frame(height: 48 * scale)
    }

    private func searchTabs(scale: CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach(["Top", "Latest", "People", "Videos", "Photos"], id: \.self) { tab in
                Text(tab)
                    .font(.system(size: 14 * scale, weight: .semibold))
                    .foregroundStyle(tab == "Top" ? XStockStyle.primary : XStockStyle.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 39 * scale)
                    .overlay(alignment: .bottom) {
                        if tab == "Top" {
                            Capsule()
                                .fill(Color(red: 0.11, green: 0.61, blue: 0.94))
                                .frame(width: 32 * scale, height: 3 * scale)
                        }
                    }
            }
        }
        .padding(.horizontal, 5 * scale)
        .overlay(alignment: .bottom) { XStockDivider() }
    }

    private func referencePost(scale: CGFloat) -> some View {
        HStack(alignment: .top, spacing: 8 * scale) {
            Image("StockPostAvatar")
                .resizable()
                .scaledToFill()
                .frame(width: 43 * scale, height: 43 * scale)
                .clipShape(Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3 * scale) {
                HStack(spacing: 3 * scale) {
                    Text("Edwin")
                        .fontWeight(.bold)
                        .foregroundStyle(XStockStyle.primary)
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Color(red: 0.11, green: 0.61, blue: 0.94))
                        .font(.system(size: 13 * scale))
                    Text("▧")
                        .foregroundStyle(XStockStyle.primary)
                    Text("@B0SIRE · 17h")
                        .foregroundStyle(XStockStyle.secondary)
                    Spacer(minLength: 0)
                    Text("𝕏")
                        .font(.system(size: 20 * scale))
                        .foregroundStyle(XStockStyle.primary)
                }
                .font(.system(size: 14 * scale))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

                Text("Not a single fintech CEO slept well last night.")
                    .font(.system(size: 14 * scale))
                    .foregroundStyle(XStockStyle.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 8 * scale)
        .padding(.top, 12 * scale)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .top) { XStockDivider() }
        .accessibilityElement(children: .combine)
    }
}

private enum XStockStyle {
    static let green = Color(red: 0, green: 0.72, blue: 0.49)
    static let red = Color(red: 0.98, green: 0.09, blue: 0.16)
    static let primary = Color(white: 0.89)
    static let secondary = Color(white: 0.40)
    static let control = Color(white: 0.135)
}

private struct XStockDivider: View {
    var body: some View {
        Rectangle().fill(Color(white: 0.10)).frame(height: 0.5)
    }
}

private struct XStockCard: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var range: XStockRange = .day
    @State private var chartStyle: XStockChartStyle = .line
    @State private var selectedFraction: Double?
    @State private var showsStyleMenu = false
    @Namespace private var rangeSelection
    let scale: CGFloat

    private var series: XStockSeries { XStockReference.series(for: range) }
    private var selection: XStockSample? {
        guard let selectedFraction else { return nil }
        if chartStyle == .line { return series.sample(at: selectedFraction) }
        return series.candles(for: chartStyle).min {
            abs($0.fraction - selectedFraction) < abs($1.fraction - selectedFraction)
        }.map { XStockSample(id: $0.id, fraction: $0.fraction, price: $0.close) }
    }

    var body: some View {
        VStack(spacing: 0) {
            quote
                .padding(.horizontal, 16 * scale)
                .padding(.top, 14 * scale)
                .padding(.bottom, 18 * scale)

            XStockPlot(
                series: series,
                style: chartStyle,
                selection: selection,
                selectedFraction: $selectedFraction,
                scale: scale
            )
            .frame(height: 204 * scale)
            .accessibilityHidden(showsStyleMenu)

            controls
                .frame(height: 57 * scale)
                .padding(.horizontal, 10 * scale)
        }
        .overlay(alignment: .bottomTrailing) {
            if showsStyleMenu {
                ZStack(alignment: .bottomTrailing) {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { setMenuVisible(false) }
                        .accessibilityHidden(true)

                    styleMenu
                        .padding(.trailing, 13 * scale)
                        .padding(.bottom, 50 * scale)
                        .accessibilityAddTraits(.isModal)
                        .transition(.scale(scale: 0.94, anchor: .bottomTrailing).combined(with: .opacity))
                }
            }
        }
        .sensoryFeedback(.selection, trigger: range)
        .sensoryFeedback(.selection, trigger: chartStyle)
        .sensoryFeedback(.selection, trigger: selection?.id)
    }

    private var quote: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 7 * scale) {
                Image("StockNVIDIA")
                    .resizable()
                    .frame(width: 33 * scale, height: 33 * scale)
                    .clipShape(Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 1 * scale) {
                    Text("NVIDIA Corp")
                        .font(.system(size: 15 * scale, weight: .medium))
                        .foregroundStyle(XStockStyle.primary)
                    Text("NVDA · $4.8T MC · USD")
                        .font(.system(size: 13 * scale))
                        .foregroundStyle(XStockStyle.secondary)
                }
            }
            .frame(height: 36 * scale, alignment: .top)

            Text(XStockReference.priceLabel(selection?.price ?? 198.87))
                .font(.system(size: 26 * scale, weight: .semibold))
                .tracking(-0.8 * scale)
                .foregroundStyle(XStockStyle.primary)
                .contentTransition(.numericText())
                .frame(height: 34 * scale, alignment: .leading)
                .accessibilityIdentifier("x-stock-price")

            Text(changeLabel)
                .font(.system(size: 13 * scale))
                .foregroundStyle((selection?.price ?? 198.87) >= comparisonPrice ? XStockStyle.green : XStockStyle.red)
                .contentTransition(.numericText())
                .frame(height: 18 * scale, alignment: .leading)
                .accessibilityIdentifier("x-stock-change")

            Label("After hours $198.52 (-0.18%)", systemImage: "clock")
                .labelStyle(.titleAndIcon)
                .font(.system(size: 12.5 * scale))
                .foregroundStyle(XStockStyle.secondary)
                .frame(height: 17 * scale, alignment: .leading)
                .opacity(selection == nil && (range == .day || range == .week) ? 1 : 0)
                .accessibilityHidden(selection != nil || (range != .day && range != .week))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: selection == nil)
    }

    private var comparisonPrice: Double {
        chartStyle == .line || range != .week ? range.comparisonPrice : 183.55
    }

    private var changeLabel: String {
        if selection == nil {
            return chartStyle == .line || range != .week ? range.changeLabel : "↑ $15.32 (+8.35%)"
        }
        let change = (selection?.price ?? 198.87) - comparisonPrice
        let percent = change / comparisonPrice * 100
        let sign = change >= 0 ? "+" : "−"
        return "\(change >= 0 ? "↑" : "↓") \(XStockReference.priceLabel(abs(change))) (\(sign)\(abs(percent).formatted(.number.precision(.fractionLength(2)).locale(Locale(identifier: "en_US"))))%)"
    }

    private var controls: some View {
        GeometryReader { geometry in
            ZStack {
                HStack(spacing: 2 * scale) {
                    ForEach(XStockRange.allCases) { item in
                        Button {
                            selectedFraction = nil
                            withAnimation(reduceMotion ? nil : .smooth(duration: 0.38)) {
                                range = item
                            }
                        } label: {
                            Text(item.rawValue)
                                .font(.system(size: 13 * scale))
                                .foregroundStyle(range == item ? XStockStyle.primary : XStockStyle.secondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 30 * scale)
                                .background {
                                    if range == item {
                                        Capsule().fill(XStockStyle.control)
                                            .matchedGeometryEffect(id: "selected-range", in: rangeSelection)
                                    }
                                }
                                .frame(height: 44 * scale)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(item.accessibilityLabel)
                        .accessibilityAddTraits(range == item ? .isSelected : [])
                        .accessibilityIdentifier("x-stock-range-\(item.rawValue)")
                    }

                    Button { setMenuVisible(!showsStyleMenu) } label: {
                        HStack(spacing: 5 * scale) {
                            XStockChartIcon(isCandlestick: chartStyle != .line)
                                .frame(width: 17 * scale, height: 17 * scale)
                            if chartStyle != .line {
                                Text(chartStyle.rawValue)
                                    .font(.system(size: 12 * scale))
                                    .lineLimit(1)
                            }
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 11 * scale, weight: .semibold))
                        }
                        .foregroundStyle(XStockStyle.primary)
                        .padding(.horizontal, 10 * scale)
                        .frame(minWidth: (chartStyle == .line ? 52 : 84) * scale)
                        .frame(height: 30 * scale)
                        .background(XStockStyle.control, in: RoundedRectangle(cornerRadius: 8 * scale))
                        .frame(height: 44 * scale)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .fixedSize(horizontal: true, vertical: false)
                    .accessibilityLabel("Chart style")
                    .accessibilityValue(chartStyle == .line ? "Line" : "\(chartStyle.rawValue) candles")
                    .accessibilityIdentifier("x-stock-chart-style")
                }
                .opacity(selection == nil ? 1 : 0)
                .allowsHitTesting(selection == nil)
                .accessibilityHidden(selection != nil)

                if let selection {
                    Text(range.timestamp(at: selection.fraction))
                        .font(.system(size: 12 * scale))
                        .foregroundStyle(XStockStyle.secondary)
                        .fixedSize()
                        .position(
                            x: min(max(selection.fraction * geometry.size.width, 86 * scale), geometry.size.width - 86 * scale),
                            y: geometry.size.height / 2
                        )
                        .accessibilityIdentifier("x-stock-timestamp")
                }
            }
            .frame(height: geometry.size.height)
        }
    }

    private var styleMenu: some View {
        VStack(spacing: 0) {
            ForEach(XStockChartStyle.allCases) { item in
                Button {
                    selectedFraction = nil
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.22)) {
                        chartStyle = item
                        showsStyleMenu = false
                    }
                } label: {
                    HStack(spacing: 5 * scale) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12 * scale, weight: .semibold))
                            .opacity(chartStyle == item ? 1 : 0)
                            .frame(width: 14 * scale)
                        Text(item.rawValue)
                            .font(.system(size: 14 * scale))
                        Spacer()
                        XStockChartIcon(isCandlestick: item != .line)
                            .frame(width: 16 * scale, height: 16 * scale)
                    }
                    .foregroundStyle(XStockStyle.primary)
                    .padding(.horizontal, 10 * scale)
                    .frame(height: 37 * scale)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item == .line ? "Line" : "\(item.rawValue) candles")
                .accessibilityAddTraits(chartStyle == item ? .isSelected : [])
                .accessibilityIdentifier("x-stock-style-\(item.rawValue)")
                if item != XStockChartStyle.allCases.last { XStockDivider() }
            }
        }
        .frame(width: 204 * scale)
        .background(Color(red: 0.105, green: 0.125, blue: 0.115).opacity(0.96), in: RoundedRectangle(cornerRadius: 12 * scale))
        .clipShape(RoundedRectangle(cornerRadius: 12 * scale))
        .shadow(color: .black.opacity(0.25), radius: 12 * scale, y: 4 * scale)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Chart styles")
    }

    private func setMenuVisible(_ visible: Bool) {
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.18)) {
            showsStyleMenu = visible
        }
    }
}

private struct XStockPlot: View {
    let series: XStockSeries
    let style: XStockChartStyle
    let selection: XStockSample?
    @Binding var selectedFraction: Double?
    let scale: CGFloat

    var body: some View {
        chart
            .accessibilityRepresentation { accessibleInspection }
    }

    private var accessibleInspection: some View {
        Slider(value: Binding(
            get: { selectedFraction ?? 1 },
            set: { selectedFraction = $0 }
        ), in: 0...1)
        .accessibilityLabel("NVIDIA stock chart, \(series.range.accessibilityLabel), \(style.rawValue)")
        .accessibilityValue(selection.map { "\(XStockReference.priceLabel($0.price)), \(series.range.timestamp(at: $0.fraction))" } ?? "$198.87")
        .accessibilityHint("Drag to inspect prices. Swipe up or down to inspect with VoiceOver.")
        .accessibilityAdjustableAction { direction in
            let fraction = selectedFraction ?? 1
            switch direction {
            case .increment: selectedFraction = min(1, fraction + 0.025)
            case .decrement: selectedFraction = max(0, fraction - 0.025)
            @unknown default: break
            }
        }
        .accessibilityAction(named: "Show latest price") { selectedFraction = nil }
        .accessibilityIdentifier("x-stock-plot")
    }

    private var chart: some View {
        Chart {
            if style == .line {
                lineMarks
            } else {
                candleMarks
            }

            if let selection {
                RuleMark(x: .value("Selected time", selection.fraction))
                    .foregroundStyle(Color(white: 0.17))
                    .lineStyle(StrokeStyle(lineWidth: 0.6 * scale))
                    .accessibilityHidden(true)
                PointMark(x: .value("Selected time", selection.fraction), y: .value("Price", selection.price))
                    .symbolSize(44 * scale * scale)
                    .foregroundStyle(XStockStyle.green)
                    .accessibilityHidden(true)
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .chartXScale(domain: 0.0...1.0, range: .plotDimension(padding: 0))
        .chartYScale(domain: series.domain, range: .plotDimension(padding: 0))
        .chartOverlay { proxy in
            GeometryReader { geometry in
                if let anchor = proxy.plotFrame {
                    let frame = geometry[anchor]
                    ZStack(alignment: .topLeading) {
                        if let selection, let x = proxy.position(forX: selection.fraction) {
                            Rectangle()
                                .fill(.black.opacity(0.68))
                                .frame(width: max(0, frame.width - x - 4 * scale), height: frame.height)
                                .offset(x: frame.minX + x + 4 * scale, y: frame.minY)
                                .allowsHitTesting(false)
                        }

                        Rectangle()
                            .fill(.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let x = min(max(value.location.x - frame.minX, 0), frame.width)
                                        selectedFraction = proxy.value(atX: x, as: Double.self)
                                    }
                                    .onEnded { _ in selectedFraction = nil }
                            )
                    }
                }
            }
        }
    }

    @ChartContentBuilder
    private var lineMarks: some ChartContent {
        if series.range == .day {
            RuleMark(y: .value("Reference price", series.domain.lowerBound + (series.domain.upperBound - series.domain.lowerBound) * 0.12))
                .lineStyle(StrokeStyle(lineWidth: 0.5 * scale, dash: [4 * scale, 4 * scale]))
                .foregroundStyle(Color(white: 0.12))
                .accessibilityHidden(true)
        }

        ForEach(series.regularLineSamples) { sample in
            AreaMark(
                x: .value("Time", sample.fraction),
                yStart: .value("Baseline", series.domain.lowerBound),
                yEnd: .value("Price", sample.price)
            )
            .foregroundStyle(LinearGradient(
                colors: [XStockStyle.green.opacity(0.38), XStockStyle.green.opacity(0.02)],
                startPoint: .top,
                endPoint: .bottom
            ))
            .interpolationMethod(.linear)
            .alignsMarkStylesWithPlotArea()

            LineMark(x: .value("Time", sample.fraction), y: .value("Price", sample.price), series: .value("Session", "Market"))
                .foregroundStyle(XStockStyle.green)
                .lineStyle(StrokeStyle(lineWidth: 1.6 * scale, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.linear)
        }

        ForEach(series.afterHoursLineSamples) { sample in
            LineMark(x: .value("Time", sample.fraction), y: .value("Price", sample.price), series: .value("Session", "After hours"))
                .foregroundStyle(Color(white: 0.45).opacity(series.afterHoursSamples.isEmpty ? 0 : 1))
                .lineStyle(StrokeStyle(lineWidth: 1.5 * scale, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.linear)
        }

        if series.range == .day, selection == nil, let last = series.samples.last {
            PointMark(x: .value("Time", last.fraction), y: .value("Price", last.price))
                .foregroundStyle(Color(white: 0.48))
                .symbolSize(37 * scale * scale)
                .accessibilityHidden(true)
        }
    }

    @ChartContentBuilder
    private var candleMarks: some ChartContent {
        let candles = series.candles(for: style)
        ForEach(candles) { candle in
            let color = candle.close >= candle.open ? XStockStyle.green : XStockStyle.red
            RuleMark(
                x: .value("Time", candle.fraction),
                yStart: .value("Low", candle.low),
                yEnd: .value("High", candle.high)
            )
            .foregroundStyle(color)
            .lineStyle(StrokeStyle(lineWidth: 0.8 * scale))

            RectangleMark(
                xStart: .value("Start", candle.fraction - 0.34 / Double(candles.count)),
                xEnd: .value("End", candle.fraction + 0.34 / Double(candles.count)),
                yStart: .value("Open", candle.open),
                yEnd: .value("Close", candle.close)
            )
            .foregroundStyle(color)
        }
    }
}

private struct XStockChartIcon: View {
    let isCandlestick: Bool

    var body: some View {
        Canvas { context, size in
            var path = Path()
            if isCandlestick {
                for (x, top, bottom) in [(0.25, 0.05, 0.86), (0.75, 0.14, 1.0)] {
                    path.move(to: CGPoint(x: size.width * x, y: size.height * top))
                    path.addLine(to: CGPoint(x: size.width * x, y: size.height * bottom))
                }
                context.stroke(path, with: .foreground, lineWidth: 1.25)
                for (x, y) in [(0.12, 0.24), (0.62, 0.46)] {
                    let rect = CGRect(x: size.width * x, y: size.height * y, width: size.width * 0.26, height: size.height * 0.32)
                    context.fill(Path(rect), with: .color(XStockStyle.control))
                    context.stroke(Path(rect), with: .foreground, lineWidth: 1.25)
                }
            } else {
                path.move(to: CGPoint(x: 0, y: size.height * 0.78))
                path.addLine(to: CGPoint(x: size.width * 0.34, y: size.height * 0.40))
                path.addLine(to: CGPoint(x: size.width * 0.57, y: size.height * 0.65))
                path.addLine(to: CGPoint(x: size.width, y: size.height * 0.18))
                context.stroke(path, with: .foreground, style: StrokeStyle(lineWidth: 1.5, lineJoin: .miter))
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview("X stock graph") {
    NavigationStack { XStockGraphDemoView() }
}
