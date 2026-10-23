# SwiftUIExperiments

## X stock graph

Open **X stock graph** from the main list for the stock-card interaction from
`main-3.mp4`. The dark search screen, NVIDIA quote, green area fill, gray after-hours
line, range pills, floating chart-style menu, and sample post follow the reference.
The five curves use fixed samples traced from the supplied video; this demo does
not fetch live market data. The logo is cropped from the reference, and the
sample post uses Edwin's supplied photo and **@B0SIRE** handle.

Choose **1D**, **1W**, **1M**, **1Y**, or **ALL** to animate between the curves.
Touch and drag anywhere on the chart to inspect a price: the crosshair follows
the selected point, later prices dim, the quote updates, and a timestamp replaces
the range controls. Releasing restores the current quote. Open the lower-right
menu to select **Line**, **30m**, **1h**, or **4h** candlesticks.

The graph uses native Swift Charts `LineMark`, `AreaMark`, `RuleMark`, `PointMark`,
and `RectangleMark` with `ChartProxy` for touch selection. The 4h weekly candles
also follow the video; other intervals aggregate the traced samples. Range and
style changes provide haptics, Reduce Motion disables transition animations,
and VoiceOver supports adjustable price inspection and a Show latest price action.
The demo supports iOS 17.5 and includes a standalone SwiftUI preview.

## Grok Bot mascots

Open **Grok Bot mascots** from the main list for the welcome-screen study from
`main-2.mp4`. All nine characters are drawn as native vector paths: green cloud,
pink blob, brown circle, purple droplet, red blob, amber circle, teal circle,
blue rounded square, and orange hexagon. The composition follows the clip's
positions, colors, slow drift, and body tilts. Each bot has its own random
expression sequence, hold durations, glances, and blink timing. Expressions
blend smoothly and stay consistent across redraws; replay creates fresh sequences.
After the reference's initial drift, the movement returns smoothly and repeats.

Tap a floating bot to cycle through brief happy, surprised, curious, and blinking
reactions. The reference's **Sign in** button opens **Meet the bots**, a local
reaction playground. It does not perform authentication. All nine are visible
in full there; choose Auto, Curious, Happy, Surprised, Sleepy, or Blink for the
whole group, or tap individual cards to change their expressions. Replay
restarts the animations; **Replay welcome** returns to the opening composition.

`GrokBotArtwork` is reusable with a bot, reaction, and time. The animations use
`TimelineView` and `Canvas` without video playback, image assets, or dependencies.
Reduce Motion holds a still pose while preserving reaction selection, and the
clock pauses when the app is inactive. The demo supports iOS 17.5 and includes
standalone welcome and gallery previews.

## Ultracode

Open **Ultracode** from the main list. The effort modal opens automatically.
Its final row fades from white to aubergine, introduces an orange pixel mascot,
then brings out an electric guitar, floating gold notes, and traveling square-grid
waves. The row animation runs independently of the selected effort, as in the
reference video. Tap an effort to select it; the selection survives closing and
reopening the modal. The replay button restarts the entrance sequence.

The guitarist uses separate pixel layers for its body, double-cutaway guitar,
fretting hand, and strumming arm, with stepped playing poses and occasional
blinks. A fixed square lattice lights up in expanding rings from the guitarist;
the first broad wash gives way to shorter pulses and overlapping echoes.

The animation uses SwiftUI `TimelineView` and `Canvas` with procedural pixel art;
no video playback, external assets, or dependencies are needed. Reduce Motion
shows a still composition, and the timeline pauses while the app is inactive.
The sheet scrolls at larger text sizes and supports the iOS 17.5 deployment target.
`UltracodeDemoView.swift` also includes a standalone preview.

## Dynamic layout

Open **Dynamic layout** from the app's main list. Touch and hold a colored rectangle,
drag to rearrange the layout live, and release to place it. Reset restores the sample order.
VoiceOver users can use the **Move earlier** and **Move later** actions.
Use the **+** toolbar button to add a rectangle with a random color, size, and
fixed or flexible width. Tap its **×** button to remove it. Insertions and removals
animate, and newly added rectangles scroll into view.

- `FlowLayout` measures each child and fills rows in array order. Rows are
  top-aligned and spaced below the tallest child; gaps below shorter children are
  intentionally left empty. Children should respect the proposed width.
- Pass `width: { item in ... }` to `ReorderableFlow` to mix `.fixed(150)` with
  `.flexible(minimum: 110)`. Rows are formed using minimum widths; flexible items
  share any remaining width equally on top of their minimums. Explicit minimums
  are preserved even if the container is narrower. The sample marks flexible
  items with an arrow badge, and recalculates their widths during reordering.
- `ReorderableFlow` accepts a binding to an array of identifiable items and a view
  builder. Replace the sample rectangles with your own components, keeping IDs
  stable. The array updates during the drag. The placeholder and surrounding components
  animate into place while the lifted component follows your finger.
- The sample uses `onDraggingChanged` to pause its surrounding scroll view while
  a rectangle is lifted. Scroll before dragging to reach additional items; this
  sample does not automatically scroll at the viewport edges.

The sample supports the project's iOS 17.5 deployment target and includes a
standalone SwiftUI preview in `DynamicLayoutDemoView.swift`.

## Animated checkbox

Using layering technique to animate a check box when selected

![check box](/Resources/screen_recording.gif "Animated Checkbox")


```swift
struct CheckMark: View {
	@State var isComplete: Bool = false
	@State var degrees = false
	@State var opacity = false

	private let cornerRadius = 12.0
	private let size = 40.0
	var onTap: (() -> Void)?
	var body: some View {
		ZStack {
			RoundedRectangle(cornerRadius: cornerRadius)
				.frame(width: size, height: size)
				.foregroundColor(.blue)
				.scaleEffect(isComplete ? 1.8 : 0)
				.opacity(opacity ? 0 : 0.5)

			RoundedRectangle(cornerRadius: isComplete ? cornerRadius : 20.0)
				.frame(width: size, height: size)
				.foregroundColor(isComplete ? .blue : .white)

			Image(systemName: "checkmark").bold()
				.opacity(isComplete ? 1.0 : 0.1)
				.foregroundColor(isComplete ? .white : .gray)
		}
		.rotationEffect(.degrees(degrees ? -20.0 : 0.0))
		.onTapGesture {
			onTap?()
			withAnimation {
				isComplete.toggle()
			}

			withAnimation(.easeInOut(duration: 0.5).delay(0.2)) {
				degrees.toggle()
				opacity.toggle()
			}

			withAnimation(.easeInOut(duration: 0.5).delay(0.7)) {
				degrees.toggle()
			}
		}
	}
}
```
