import SwiftUI

struct CoverFlowDemoView: View {
	@Environment(\.accessibilityReduceMotion) private var reduceMotion
	@Environment(\.dismiss) private var dismiss

	@State private var focusedBookID: CoverFlowBook.ID? = CoverFlowBook.samples[2].id
	@State private var selectedBook: CoverFlowBook?
	@State private var selectedSourceFrame = CGRect.zero
	@State private var presentationProgress = CoverFlowPresentationStage.cover.progress
	@State private var settledStage = CoverFlowPresentationStage.cover
	@State private var dragStartStage: CoverFlowPresentationStage?
	@State private var isAnimatingPresentation = false
	@State private var feedbackTrigger = 0

	var body: some View {
		GeometryReader { geometry in
			ZStack {
				CoverFlowBackground()

				CoverFlowLibraryView(
					books: CoverFlowBook.samples,
					focusedBookID: $focusedBookID,
					hiddenBookID: selectedBook?.id,
					onDismiss: dismiss.callAsFunction,
					onSelect: openDetail
				)
				.modifier(CoverFlowLibraryPresentationEffect(progress: presentationProgress))
				.allowsHitTesting(selectedBook == nil)
				.accessibilityHidden(selectedBook != nil)

				if let selectedBook {
					CoverFlowHeroView(
						book: selectedBook,
						sourceFrame: selectedSourceFrame,
						containerSize: geometry.size,
						safeAreaInsets: geometry.safeAreaInsets,
						progress: presentationProgress,
						reduceMotion: reduceMotion,
						canExpand: settledStage == .detail && !isAnimatingPresentation,
						isInteractive: settledStage != .cover && !isAnimatingPresentation,
						onClose: closeDetail,
						onExpand: openFullscreen
					)
					.simultaneousGesture(presentationDragGesture(containerHeight: geometry.size.height))
					.zIndex(10)
				}
			}
			.coordinateSpace(.named(CoverFlowCoordinateSpace.root))
		}
		.toolbar(.hidden, for: .navigationBar)
		.preferredColorScheme(.light)
		.sensoryFeedback(.selection, trigger: feedbackTrigger)
	}

	private var heroAnimation: Animation {
		reduceMotion
			? .easeInOut(duration: 0.2)
			: .spring(duration: 0.68, bounce: 0.14)
	}

	private func openDetail(_ book: CoverFlowBook, sourceFrame: CGRect) {
		guard selectedBook == nil else { return }

		selectedSourceFrame = sourceFrame
		presentationProgress = CoverFlowPresentationStage.cover.progress
		settledStage = .cover
		dragStartStage = nil
		isAnimatingPresentation = true
		selectedBook = book
		feedbackTrigger += 1

		Task { @MainActor in
			await Task.yield()
			animatePresentation(to: .detail)
		}
	}

	private func closeDetail() {
		guard selectedBook != nil, !isAnimatingPresentation else { return }

		dragStartStage = nil
		feedbackTrigger += 1
		animatePresentation(to: .cover)
	}

	private func openFullscreen() {
		guard selectedBook != nil, settledStage == .detail, !isAnimatingPresentation else { return }

		feedbackTrigger += 1
		animatePresentation(to: .fullscreen)
	}

	private func animatePresentation(to target: CoverFlowPresentationStage) {
		isAnimatingPresentation = true
		withAnimation(heroAnimation, completionCriteria: .removed) {
			presentationProgress = target.progress
		} completion: {
			guard presentationProgress == target.progress else { return }

			settledStage = target
			isAnimatingPresentation = false
			if target == .cover {
				selectedBook = nil
			}
		}
	}

	private func restorePresentation(to stage: CoverFlowPresentationStage) {
		animatePresentation(to: stage)
	}

	private func presentationDragGesture(containerHeight: CGFloat) -> some Gesture {
		DragGesture(minimumDistance: 10)
			.onChanged { value in
				guard selectedBook != nil, !isAnimatingPresentation, settledStage != .cover else { return }

				if dragStartStage == nil {
					dragStartStage = settledStage
				}
				guard let dragStartStage else { return }

				let downwardTranslation = max(0, value.translation.height)
				let dismissalDistance = max(240, containerHeight * 0.7)
				let dragFraction = (downwardTranslation / dismissalDistance).clamped(to: 0...1)
				var transaction = Transaction()
				transaction.animation = nil
				withTransaction(transaction) {
					presentationProgress = dragStartStage.progress * (1 - dragFraction)
				}
			}
			.onEnded { value in
				guard let dragStartStage else { return }

				let predictedDownwardTranslation = max(0, value.predictedEndTranslation.height)
				let progressTravelled = dragStartStage.progress - presentationProgress
				let shouldClose = predictedDownwardTranslation > 150 || progressTravelled > 0.22
				self.dragStartStage = nil

				if shouldClose {
					closeDetail()
				} else {
					restorePresentation(to: dragStartStage)
				}
			}
	}
}

private enum CoverFlowPresentationStage {
	case cover
	case detail
	case fullscreen

	var progress: CGFloat {
		switch self {
		case .cover: 0
		case .detail: 1
		case .fullscreen: 2
		}
	}
}

private struct CoverFlowLibraryPresentationEffect: ViewModifier, Animatable {
	var progress: CGFloat

	var animatableData: CGFloat {
		get { progress }
		set { progress = newValue }
	}

	func body(content: Content) -> some View {
		let detailProgress = progress.clamped(to: 0...1)

		content
			.scaleEffect(1 - (detailProgress * 0.035))
			.blur(radius: detailProgress * 5)
			.opacity(1 - (detailProgress * 0.3))
	}
}

private struct CoverFlowLibraryView: View {
    let books: [CoverFlowBook]
    @Binding var focusedBookID: CoverFlowBook.ID?
    let hiddenBookID: CoverFlowBook.ID?
    let onDismiss: () -> Void
    let onSelect: (CoverFlowBook, CGRect) -> Void

    var body: some View {
        GeometryReader { geometry in
            let cardWidth = max(1, min(geometry.size.width * 0.46, 280, max(100, geometry.size.height * 0.46)))
            let cardHeight = cardWidth * 1.46
            VStack(spacing: 0) {
                CoverFlowHeader(onDismiss: onDismiss)
                GeometryReader { viewport in
                    ScrollView {
                        VStack(spacing: 0) {
                            Spacer(minLength: 24)
                            ScrollView(.horizontal) {
                                LazyHStack(spacing: 14) {
                                    ForEach(books) { book in
                                        CoverFlowBookButton(book: book,
                                            cardSize: CGSize(width: cardWidth, height: cardHeight),
                                            isHidden: hiddenBookID == book.id, onSelect: onSelect)
                                            .id(book.id)
                                    }
                                }
                                .scrollTargetLayout()
                            }
                            .contentMargins(.horizontal, max(24, (geometry.size.width - cardWidth) / 2), for: .scrollContent)
                            .scrollIndicators(.hidden)
                            .scrollTargetBehavior(.viewAligned)
                            .scrollPosition(id: $focusedBookID, anchor: .center)
                            .frame(height: cardHeight + 56)
                            .accessibilityIdentifier("cover-flow-carousel")
                            Spacer(minLength: 20)
                            Text("Swipe to browse  •  Tap a cover")
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(.secondary)
                                .padding(.bottom, 28)
                        }
                        .frame(minHeight: viewport.size.height)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .accessibilityIdentifier("cover-flow-scroll")
                }
            }
        }
    }
}

private struct CoverFlowBookButton: View {
	@State private var frame = CGRect.zero

	let book: CoverFlowBook
	let cardSize: CGSize
	let isHidden: Bool
	let onSelect: (CoverFlowBook, CGRect) -> Void

	var body: some View {
		Button {
			onSelect(book, frame)
		} label: {
			BookCoverView(book: book)
				.frame(width: cardSize.width, height: cardSize.height)
		}
		.buttonStyle(.plain)
		.opacity(isHidden ? 0 : 1)
		.scrollTransition(.interactive, axis: .horizontal) { content, phase in
			let distance = CGFloat(abs(phase.value))
			let scale = 1 - (distance * 0.2)
			let verticalOffset = distance * 24
			let opacity = 1 - (distance * 0.28)
			return content
				.scaleEffect(scale)
				.offset(y: verticalOffset)
				.opacity(opacity)
		}
		.onGeometryChange(for: CGRect.self) { proxy in
			proxy.frame(in: .named(CoverFlowCoordinateSpace.root))
		} action: { newFrame in
			frame = newFrame
		}
		.accessibilityLabel("\(book.title), by \(book.author)")
		.accessibilityHint("Opens the book details")
        .accessibilityIdentifier("cover-flow-book-\(book.id)")
	}
}

private struct CoverFlowHeader: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
	let onDismiss: () -> Void

	var body: some View {
		HStack(alignment: .top) {
			Button(action: onDismiss) {
				Image(systemName: "chevron.left")
					.font(.system(size: 17, weight: .bold))
					.frame(width: 42, height: 42)
					.background(.black.opacity(0.07), in: .circle)
			}
			.buttonStyle(.plain)
			.accessibilityLabel("Back")
            .accessibilityIdentifier("close-cover-flow-demo")

            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    Text("Now Reading")
                        .font(.system(.title2, design: .serif, weight: .black))
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    VStack(alignment: .leading, spacing: -2) {
                        Text("I’m")
                        Text("Now")
                        Text("Reading")
                    }
                    .font(.system(.largeTitle, design: .serif, weight: .black))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !dynamicTypeSize.isAccessibilitySize {
			Circle()
				.fill(
					AngularGradient(
						colors: [.cyan, .indigo, .pink, .orange, .cyan],
						center: .center
					)
				)
				.frame(width: 46, height: 46)
				.overlay {
					Circle().fill(.white.opacity(0.28)).padding(9)
				}
				.accessibilityHidden(true)
            }
		}
		.padding(.horizontal, 20)
		.padding(.top, 10)
	}
}

private struct CoverFlowHeroView: View, Animatable {
	let book: CoverFlowBook
	let sourceFrame: CGRect
	let containerSize: CGSize
	let safeAreaInsets: EdgeInsets
	var progress: CGFloat
	let reduceMotion: Bool
	let canExpand: Bool
	let isInteractive: Bool
	let onClose: () -> Void
	let onExpand: () -> Void

	var animatableData: CGFloat {
		get { progress }
		set { progress = newValue }
	}

	private var resolvedSourceFrame: CGRect {
		guard sourceFrame.width > 0, sourceFrame.height > 0 else {
			let width = min(containerSize.width * 0.46, 190)
			let height = width * 1.46
			return CGRect(
				x: (containerSize.width - width) / 2,
				y: (containerSize.height - height) / 2,
				width: width,
				height: height
			)
		}
		return sourceFrame
	}

	private var destinationFrame: CGRect {
		let width = max(1, min(containerSize.width - 24, 680))
		let height = max(1, min(containerSize.height - 24, 900))
		return CGRect(
			x: (containerSize.width - width) / 2,
			y: (containerSize.height - height) / 2,
			width: width,
			height: height
		)
	}

	private var fullscreenFrame: CGRect {
		CGRect(
			x: -safeAreaInsets.leading,
			y: -safeAreaInsets.top,
			width: containerSize.width + safeAreaInsets.leading + safeAreaInsets.trailing,
			height: containerSize.height + safeAreaInsets.top + safeAreaInsets.bottom
		)
	}

	private var resolvedProgress: CGFloat {
		progress.clamped(to: 0...2)
	}

	private var detailProgress: CGFloat {
		resolvedProgress.clamped(to: 0...1)
	}

	private var fullscreenProgress: CGFloat {
		(resolvedProgress - 1).clamped(to: 0...1)
	}

	private var currentFrame: CGRect {
		if resolvedProgress <= 1 {
			return CGRect.interpolate(
				from: resolvedSourceFrame,
				to: destinationFrame,
				progress: detailProgress
			)
		}

		return CGRect.interpolate(
			from: destinationFrame,
			to: fullscreenFrame,
			progress: fullscreenProgress
		)
	}

	private var rotation: Double {
		reduceMotion ? 0 : Double(detailProgress) * 180
	}

	private var backOpacity: Double {
		if reduceMotion {
			return Double(detailProgress)
		}
		return detailProgress >= 0.5 ? 1 : 0
	}

	private var frontOpacity: Double {
		if reduceMotion {
			return Double(1 - detailProgress)
		}
		return detailProgress < 0.5 ? 1 : 0
	}

	private var cornerRadius: CGFloat {
		if resolvedProgress <= 1 {
			return 18 + (detailProgress * 12)
		}

		return 30 * (1 - fullscreenProgress)
	}

	var body: some View {
		let frame = currentFrame
		let source = resolvedSourceFrame
		let frontScaleX = frame.width / source.width
		let frontScaleY = frame.height / source.height
		let shadowVisibility = 1 - fullscreenProgress

		ZStack {
			BookCoverView(book: book)
				.frame(width: source.width, height: source.height)
				.scaleEffect(x: frontScaleX, y: frontScaleY)
				.opacity(frontOpacity)
				.accessibilityHidden(detailProgress >= 0.5)

			BookDetailBackView(
				book: book,
				contentSize: frame.size,
                safeAreaInsets: EdgeInsets(top: safeAreaInsets.top * fullscreenProgress,
                                          leading: safeAreaInsets.leading * fullscreenProgress,
                                          bottom: safeAreaInsets.bottom * fullscreenProgress,
                                          trailing: safeAreaInsets.trailing * fullscreenProgress),
				fullscreenProgress: fullscreenProgress,
				canExpand: canExpand,
				onClose: onClose,
				onExpand: onExpand
			)
				.frame(width: frame.width, height: frame.height)
				.rotation3DEffect(
					.degrees(reduceMotion ? 0 : 180),
					axis: (x: 0, y: 1, z: 0),
					anchor: .center,
					perspective: 0.65
				)
				.opacity(backOpacity)
				.allowsHitTesting(isInteractive)
				.accessibilityHidden(!isInteractive)
		}
		.frame(width: frame.width, height: frame.height)
		.compositingGroup()
		.clipShape(.rect(cornerRadius: cornerRadius, style: .continuous))
		.overlay {
			RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
				.stroke(.white.opacity(0.55 * shadowVisibility), lineWidth: 1)
		}
		.rotation3DEffect(
			.degrees(rotation),
			axis: (x: 0, y: 1, z: 0),
			anchor: .center,
			perspective: 0.65
		)
		.shadow(
			color: .black.opacity((0.18 + (detailProgress * 0.08)) * shadowVisibility),
			radius: 22 * shadowVisibility,
			y: 14 * shadowVisibility
		)
		.position(x: frame.midX, y: frame.midY)
		.accessibilityIdentifier(fullscreenProgress > 0.99 ? "coverFlow.fullscreen" : "coverFlow.detail")
		.accessibilityAction(.escape) {
			if isInteractive {
				onClose()
			}
		}
	}
}

private struct BookDetailBackView: View {
    let book: CoverFlowBook
    let contentSize: CGSize
    let safeAreaInsets: EdgeInsets
    let fullscreenProgress: CGFloat
    let canExpand: Bool
    let onClose: () -> Void
    let onExpand: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ZStack {
            LinearGradient(colors: [book.detailColor, .white, book.detailColor.opacity(0.72)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(spacing: 12) {
                HStack {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(width: 44, height: 44)
                            .background(.black.opacity(0.08), in: Circle())
                    }
                    .accessibilityLabel("Close details")
                    Spacer()
                    if canExpand {
                        Button(action: onExpand) {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: 17))
                                .frame(width: 44, height: 44)
                                .background(.black.opacity(0.08), in: Circle())
                        }
                        .accessibilityLabel("Open \(book.title) full screen")
                        .accessibilityIdentifier("cover-flow-expand")
                    }
                }
                .buttonStyle(.plain)
                ScrollView {
                    VStack(spacing: 18) {
                        BookCoverView(book: book, showsShadow: false)
                            .frame(width: 104, height: 152)
                            .accessibilityHidden(true)
                        VStack(spacing: 6) {
                            Text(book.title)
                                .font(.system(.title, design: .serif, weight: .bold))
                            Text(book.author)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        Text(book.blurb)
                            .font(.body)
                            .foregroundStyle(.black.opacity(0.72))
                            .lineSpacing(4)
                        metadata
                            .padding(.vertical, 14)
                            .background(.white.opacity(0.48), in: RoundedRectangle(cornerRadius: 18))
                        Label("Drag down to close", systemImage: "arrow.down")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .opacity(1 - fullscreenProgress)
                    }
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 640)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 16)
                    .contentShape(Rectangle())
                    .onTapGesture { if canExpand { onExpand() } }
                }
                .scrollBounceBehavior(.basedOnSize)
                .accessibilityIdentifier("book-detail-scroll")
            }
            .padding(20)
            .padding(safeAreaInsets)
        }
        .frame(width: contentSize.width, height: contentSize.height)
    }

    private var metadata: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 16)) : AnyLayout(HStackLayout(spacing: 0))
        return layout {
            BookMetadata(value: book.pageCount, label: "Pages")
            BookMetadata(value: book.published, label: "Published")
            BookMetadata(value: book.readingTime, label: "Reading")
        }
    }
}

private struct BookMetadata: View {
	let value: String
	let label: String

	var body: some View {
		VStack(spacing: 3) {
			Text(value)
				.font(.subheadline.weight(.bold))
			Text(label)
				.font(.caption)
				.foregroundStyle(.secondary)
		}
		.frame(maxWidth: .infinity)
		.accessibilityElement(children: .combine)
	}
}

private struct BookCoverView: View {
	let book: CoverFlowBook
	var showsShadow = true

	var body: some View {
		ZStack {
			LinearGradient(
				colors: book.coverColors,
				startPoint: .topLeading,
				endPoint: .bottomTrailing
			)

			book.artwork

			VStack(alignment: .leading, spacing: 8) {
				Text(book.kicker.uppercased())
					.font(.caption2.weight(.bold))
					.tracking(1.4)
					.opacity(0.72)

				Text(book.title)
					.font(.system(.title2, design: .serif, weight: .black))
					.minimumScaleFactor(0.55)
					.lineLimit(3)

				Spacer()

				Text(book.author)
					.font(.caption.weight(.semibold))
					.opacity(0.8)
			}
			.foregroundStyle(book.coverForeground)
			.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
			.padding(18)

			Rectangle()
				.fill(.white.opacity(0.22))
				.frame(width: 2)
				.frame(maxHeight: .infinity)
				.frame(maxWidth: .infinity, alignment: .leading)
				.padding(.leading, 8)
				.accessibilityHidden(true)
		}
        // Printed cover artwork keeps its proportions. The button label and
        // the separate title and author in the details support Dynamic Type.
        .environment(\.dynamicTypeSize, .large)
        .accessibilityHidden(true)
		.compositingGroup()
		.clipShape(.rect(cornerRadius: 18, style: .continuous))
		.overlay {
			RoundedRectangle(cornerRadius: 18, style: .continuous)
				.stroke(.white.opacity(0.5), lineWidth: 1)
		}
		.shadow(
			color: showsShadow ? .black.opacity(0.2) : .clear,
			radius: showsShadow ? 14 : 0,
			y: showsShadow ? 10 : 0
		)
	}
}

private struct CoverFlowBackground: View {
	var body: some View {
		ZStack {
			Color(red: 0.95, green: 0.94, blue: 0.9)
			RadialGradient(
				colors: [.white.opacity(0.9), .clear],
				center: .topTrailing,
				startRadius: 20,
				endRadius: 380
			)
		}
		.ignoresSafeArea()
	}
}

private struct CoverFlowBook: Identifiable {
	enum Style {
		case midnight
		case citrus
		case rose
		case meadow
		case paper
	}

	let id: String
	let title: String
	let author: String
	let kicker: String
	let blurb: String
	let pageCount: String
	let published: String
	let readingTime: String
	let style: Style

	var coverColors: [Color] {
		switch style {
		case .midnight: [.indigo, Color(red: 0.06, green: 0.12, blue: 0.3)]
		case .citrus: [Color(red: 1, green: 0.78, blue: 0.26), Color(red: 0.94, green: 0.31, blue: 0.17)]
		case .rose: [Color(red: 0.98, green: 0.74, blue: 0.75), Color(red: 0.74, green: 0.12, blue: 0.3)]
		case .meadow: [Color(red: 0.78, green: 0.9, blue: 0.67), Color(red: 0.08, green: 0.38, blue: 0.28)]
		case .paper: [Color(red: 0.98, green: 0.95, blue: 0.86), Color(red: 0.82, green: 0.73, blue: 0.55)]
		}
	}

	var coverForeground: Color {
		style == .paper ? .black.opacity(0.82) : .white
	}

	var detailColor: Color {
		switch style {
		case .midnight: Color(red: 0.77, green: 0.81, blue: 0.96)
		case .citrus: Color(red: 1, green: 0.86, blue: 0.58)
		case .rose: Color(red: 0.98, green: 0.8, blue: 0.83)
		case .meadow: Color(red: 0.78, green: 0.9, blue: 0.78)
		case .paper: Color(red: 0.91, green: 0.86, blue: 0.72)
		}
	}

	var accentColor: Color {
		coverColors[1]
	}

	@ViewBuilder
	var artwork: some View {
		switch style {
		case .midnight:
			ForEach(0..<4, id: \.self) { index in
				Circle()
					.stroke(.white.opacity(0.18), lineWidth: 2)
					.frame(width: CGFloat(80 + (index * 42)))
					.offset(x: 72, y: 35)
			}
		case .citrus:
			Circle()
				.fill(.yellow.opacity(0.72))
				.frame(width: 180, height: 180)
				.offset(x: 64, y: -36)
		case .rose:
			VStack(spacing: -18) {
				ForEach(0..<5, id: \.self) { _ in
					Capsule()
						.fill(.white.opacity(0.2))
						.frame(width: 180, height: 52)
				}
			}
			.rotationEffect(.degrees(-24))
			.offset(x: 54, y: 24)
		case .meadow:
			Image(systemName: "leaf.fill")
				.font(.system(size: 170))
				.foregroundStyle(.white.opacity(0.18))
				.rotationEffect(.degrees(-18))
				.offset(x: 56, y: 40)
		case .paper:
			RoundedRectangle(cornerRadius: 4)
				.fill(.black.opacity(0.08))
				.frame(width: 130, height: 180)
				.rotationEffect(.degrees(8))
				.offset(x: 58, y: 32)
		}
	}
}

private extension CoverFlowBook {
	static let samples: [CoverFlowBook] = [
		CoverFlowBook(
			id: "the-long-way-home",
			title: "The Long Way Home",
			author: "Mara Voss",
			kicker: "A novel",
			blurb: "A quiet, luminous story about the places we leave behind and the small rituals that lead us back to ourselves.",
			pageCount: "312",
			published: "2024",
			readingTime: "6h 20m",
			style: .paper
		),
		CoverFlowBook(
			id: "bright-objects",
			title: "Bright Objects",
			author: "Nia Brooks",
			kicker: "Essays",
			blurb: "A sharp collection about wonder, attention, and the surprising gravity of ordinary things.",
			pageCount: "224",
			published: "2025",
			readingTime: "4h 10m",
			style: .rose
		),
		CoverFlowBook(
			id: "the-deep-blue",
			title: "The Deep Blue",
			author: "Elliot Vale",
			kicker: "Exploration",
			blurb: "An atmospheric journey through the unseen currents that shape oceans, weather, and memory.",
			pageCount: "368",
			published: "2026",
			readingTime: "7h 05m",
			style: .midnight
		),
		CoverFlowBook(
			id: "where-light-grows",
			title: "Where Light Grows",
			author: "Amelia Hart",
			kicker: "Nature",
			blurb: "A field guide to resilience, told through gardens, wild edges, and the people who tend them.",
			pageCount: "280",
			published: "2023",
			readingTime: "5h 35m",
			style: .meadow
		),
		CoverFlowBook(
			id: "small-suns",
			title: "Small Suns",
			author: "Theo James",
			kicker: "Stories",
			blurb: "Warm, vivid stories about ambition, friendship, and the glow we borrow from one another.",
			pageCount: "248",
			published: "2025",
			readingTime: "4h 45m",
			style: .citrus
		),
	]
}

private enum CoverFlowCoordinateSpace {
	static let root = "coverFlowRoot"
}

private extension CGFloat {
	func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
		Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
	}
}

private extension CGRect {
	static func interpolate(from start: CGRect, to end: CGRect, progress: CGFloat) -> CGRect {
		let progress = progress.clamped(to: 0...1)
		return CGRect(
			x: start.minX + ((end.minX - start.minX) * progress),
			y: start.minY + ((end.minY - start.minY) * progress),
			width: start.width + ((end.width - start.width) * progress),
			height: start.height + ((end.height - start.height) * progress)
		)
	}
}

#Preview("Cover Flow") {
	CoverFlowDemoView()
}
