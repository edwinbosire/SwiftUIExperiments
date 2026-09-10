//
//  IntensityPickerStyle.swift
//  UI-Experiments
//
//  Every measurement, colour and animation the picker uses. Callers restyle the
//  control by passing a different value rather than by editing the views, so the
//  control stays open for extension and closed for modification.
//
//  The numbers below were measured off the reference recording on a 393 point
//  wide screen, then reduced to the relationships that produce them:
//
//    knob inset  = (trackHeight - knobDiameter) / 2 = 4
//    knob centre at the first stop = trackHeight / 2 = 22
//    fill trailing edge = knob centre + trackHeight / 2
//
//  Those three lines are what give the leftmost stop its blue ring: the fill has
//  collapsed into a circle sitting directly under the knob.
//

import SwiftUI

struct IntensityPickerStyle {
	var metrics: Metrics
	var colors: Colors
	var typography: Typography
	var motion: Motion

	static let `default` = IntensityPickerStyle(metrics: .default,
												colors: .default,
												typography: .default,
												motion: .default)

	struct Metrics {
		/// Height of the track the knob runs inside.
		var trackHeight: CGFloat
		var knobDiameter: CGFloat
		var stopDiameter: CGFloat
		/// Inset between the outer container and the track.
		var containerInset: CGSize
		/// Gap between the readout and the container.
		var readoutSpacing: CGFloat
		var knobPressedScale: CGFloat
		/// Extra slop around the knob that still counts as grabbing it.
		var grabTolerance: CGFloat
		var backdropBlur: CGFloat
		/// Point the reveal animation scales out of, in unit space.
		var revealAnchor: UnitPoint

		static let `default` = Metrics(trackHeight: 44,
									   knobDiameter: 36,
									   stopDiameter: 8,
									   containerInset: CGSize(width: 8, height: 6),
									   readoutSpacing: 14,
									   knobPressedScale: 1.05,
									   grabTolerance: 14,
									   backdropBlur: 12,
									   revealAnchor: UnitPoint(x: 0.78, y: 1.6))
	}

	struct Colors {
		var container: Color
		var containerStroke: Color
		var track: Color
		var fill: Color
		var knob: Color
		var knobShadow: Color
		var stop: Color
		var stopOnFill: Color
		var readout: Color
		var backdrop: Color

		static let `default` = Colors(container: Color(white: 0.07),
									  containerStroke: Color.white.opacity(0.08),
									  track: Color(white: 0.10),
									  fill: Color(red: 0.22, green: 0.58, blue: 1.0),
									  knob: .white,
									  knobShadow: Color.black.opacity(0.45),
									  stop: Color(white: 0.30),
									  stopOnFill: Color.white.opacity(0.16),
									  readout: .white,
									  backdrop: Color.black.opacity(0.45))
	}

	struct Typography {
		var readout: Font

		static let `default` = Typography(readout: .system(size: 17, weight: .semibold))
	}

	struct Motion {
		var snap: Animation
		var readout: Animation
		var reveal: Animation
		/// Substituted whenever the system asks for reduced motion.
		var reduced: Animation

		static let `default` = Motion(snap: .spring(response: 0.34, dampingFraction: 0.72),
									  readout: .easeOut(duration: 0.18),
									  reveal: .spring(response: 0.38, dampingFraction: 0.78),
									  reduced: .easeOut(duration: 0.2))

		func snapAnimation(reduceMotion: Bool) -> Animation {
			reduceMotion ? reduced : snap
		}

		func revealAnimation(reduceMotion: Bool) -> Animation {
			reduceMotion ? reduced : reveal
		}
	}
}
