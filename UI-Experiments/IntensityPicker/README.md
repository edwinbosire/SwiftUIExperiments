# Intensity picker

A three stop intensity slider rebuilt from the reference screen recording, plus
the presentation around it: the content behind blurs and dims, the panel grows
out of the button that opened it, and a tap outside dismisses it.

## Files

| File | Responsibility |
| --- | --- |
| `IntensityLevel.swift` | The model for one stop. Nothing about layout. |
| `IntensityPickerStyle.swift` | Metrics, colours, type and motion. Restyle by passing a value, not by editing views. |
| `IntensityTrackGeometry.swift` | Pure layout maths. No SwiftUI, so the snapping rules can be unit tested on their own. |
| `IntensityPicker.swift` | The control: track, fill, stops, knob, drag, snap, haptics, accessibility. |
| `IntensityPickerOverlay.swift` | The reveal. A view modifier, so any screen can host the control. |
| `ComposerBar.swift` | Mock composer with the gauge button. |
| `MockKeyboardView.swift` | Decorative keyboard. The system keyboard cannot be blurred by an overlay, so the demo draws its own. |
| `IntensityPickerDemoView.swift` | The assembled screen. |

## Geometry

Measured off the recording on a 393 point wide screen, then reduced to the
relationships that produce those numbers:

```
track height        44
knob diameter       36
knob inset          (44 - 36) / 2 = 4
first stop centre   44 / 2 = 22
fill trailing edge  knob centre + 44 / 2
outer container     track inset by 8 horizontally and 6 vertically
panel side margins  44
```

The last two lines are the whole trick behind the leftmost state. The fill is
always a capsule from the leading edge to just past the knob, so at the first
stop it has collapsed into a circle sitting directly under the knob, and the 4
point overhang reads as a ring. No special case in the drawing code.

## Behaviour

- Dragging tracks the finger continuously. Grabbing the knob keeps the offset,
  so the knob does not jump under the fingertip. Touching the bare track pulls
  the knob over with a spring.
- The readout and the selection binding update the moment you cross a stop, not
  on release, which is what makes the label feel live.
- Releasing snaps to the nearest stop with a spring.
- `sensoryFeedback(.selection,)` fires on each crossing.
- The control is one accessibility element with an adjustable action, so
  VoiceOver users swipe up and down through the stops.
- Reduce Motion swaps every spring for a short ease out.

## Using it elsewhere

```swift
@State private var selection = IntensityLevel.medium.id

someScreen
    .intensityPicker(isPresented: $isPresented,
                     levels: IntensityLevel.standard,
                     selection: $selection,
                     bottomInset: 80)
```

Or drop `IntensityPicker(levels:selection:)` straight into a layout and skip the
overlay. It takes any number of stops, not just three.
