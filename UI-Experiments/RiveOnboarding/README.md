# Rive Onboarding

Open **Rive Onboarding** from the main feature list. A three-step travel
onboarding flow introduces the app, asks for a travel style, and personalizes
a boarding pass with an optional first name. Mountains, coast, and city each
have their own Rive scenery. Finishing lifts the suitcase, adds arrival sparkles, and reveals a
confirmation screen. **Start exploring** returns to the feature list.

The boarding pass has a three-character airport split-flap display with a city
caption. It continuously cycles **LHR / London → JFK / New York → NBO / Nairobi
→ CPT / Cape Town → DUB / Dublin → LHR**, changing every six seconds. Each
character has independently clipped upper and lower faces and a staggered
hinge turn. A plane follows the dotted orbit around the globe on the same
30-second Rive timeline, with each flap change finishing at the next stop.
The flight stays in front of the luggage and clear of the airport codes.

[Watch the iPhone preview](../../Resources/Previews/rive-onboarding-airports.mp4).

Back preserves the draft, Skip jumps to the name step, and Replay starts at
the introduction with the chosen preferences. The name, travel style, and
completion flag are stored locally under `riveOnboarding.*`. This demo always
opens at the introduction so it can be replayed; it does not book a trip.

## Runtime and source

- Official `RiveRuntime` Swift package, pinned to **6.28.1**.
- Authored with **Rive CLI 1.7.0**; editable source is in
  [`../../Rive/TravelOnboarding`](../../Rive/TravelOnboarding).
- Bundled asset: `Resources/TravelOnboarding.riv` (all fonts embedded, no CDN).
- Artboard: `Travel Onboarding`; state machine: `Onboarding`;
  view model: `TravelOnboarding`; exported instance: `Default`.
- `TravelRiveController` retains the exact auto-bound instance and checks the
  property contract on load. File errors leave native onboarding usable.

The native controls stay accessible to VoiceOver and Dynamic Type. The Rive
artwork is decorative, with its information repeated in the native controls.
Playback pauses when the feature disappears or the app becomes inactive.
Reduce Motion selects still poses and pauses the display link; data and text
changes still render.

## Binding contract

| Property | Type | Effect |
| --- | --- | --- |
| `progress` | Number, 0–100 | Boarding-pass progress fill |
| `travelStyle` | Number, 0 / 50 / 100 | Mountains / coast / city blend |
| `travelerName` | String | Boarding-pass traveller name |
| `accentColor` | Color | Boarding-pass progress color |
| `isComplete` | Boolean | Suitcase lift and arrival sparkles |
| `reduceMotion` | Boolean | Still anticipation / arrival poses |
| `motionDuration` | Number, seconds | Scenery transition duration; zero with Reduce Motion |

These are Rive view model properties, not deprecated state machine inputs.
Native state is owned by `TravelOnboardingState`; `TravelRiveController` writes
it to the retained Rive instance when it changes.

Airport codes and city captions are keyed inside Rive's `Around the world`
timeline, alongside the flight and individual flap faces. Native code does
not set the destination or run a cycling timer. The cycle continues through
onboarding completion; Reduce Motion selects the settled London pose.

## Rebuild after editing the artwork

From the repository root:

```sh
rive Rive/TravelOnboarding
bash scripts/build-rive-onboarding.sh
```

The first command opens Rive's live preview; the second verifies and inspects
the source, compiles it, and updates the asset copied into the app. Building
the iOS project does not require the CLI or a Rive account. This asset uses
RML vectors, timelines, and data binding without scripts or remote assets.

DM Mono is distributed under the SIL Open Font License. Its license is in
the source font directory and `Resources/DMMono-LICENSE.txt`.

## Validation

The iPhone 17 Pro simulator build exercises the real bundled `.riv`. Targeted
unit tests check navigation boundaries, the actual boarding-pass text bindings,
all five airport codes/cities, the return to London, continued cycling after
completion, and Reduce Motion. UI tests cover style selection, editing the name, Back, completion,
Replay, Skip, saved preferences, and navigation at accessibility text size.
