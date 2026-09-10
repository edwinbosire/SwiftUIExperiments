//
//  IntensityLevel.swift
//  UI-Experiments
//
//  One selectable stop on the intensity track.
//

import Foundation

struct IntensityLevel: Identifiable, Hashable {
	let id: String

	/// Name shown in the readout above the track.
	let title: String

	/// Optional value shown before the title, for example a model number.
	let prefix: String?

	/// Symbol a host view can use to mirror the level on a button.
	let systemImage: String?

	init(id: String? = nil,
		 title: String,
		 prefix: String? = nil,
		 systemImage: String? = nil) {
		self.id = id ?? title.lowercased()
		self.title = title
		self.prefix = prefix
		self.systemImage = systemImage
	}

	var displayName: String {
		guard let prefix else { return title }
		return "\(prefix) \(title)"
	}
}

extension IntensityLevel {
	static let low = IntensityLevel(title: "Low",
									systemImage: "gauge.with.dots.needle.bottom.0percent")
	static let medium = IntensityLevel(title: "Medium",
									   systemImage: "gauge.with.dots.needle.bottom.50percent")
	static let high = IntensityLevel(title: "High",
									 systemImage: "gauge.with.dots.needle.bottom.100percent")

	/// The three stop configuration used by the demo.
	static let standard: [IntensityLevel] = [.low, .medium, .high]
}
