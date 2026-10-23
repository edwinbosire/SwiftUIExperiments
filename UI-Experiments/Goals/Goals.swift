//
//  Goals.swift
//  UI-Experiments
//
//  Created by Edwin Bosire on 25/01/2025.
//

import SwiftUI

struct Goals: View {
	var body: some View {
		NavigationView {
			ScrollView {
				VStack(spacing: 16) {
					CategoryRow(category: "Learn New Skills", image: "person.2", users: 15.2)
					CategoryRow(category: "Exercise Regularly", image: "figure.run", users: 12.4)
					CategoryRow(category: "Visit New Places", image: "landscape", users: 10.9)
					CategoryRow(category: "Learn a New Language", image: "globe", users: 14.8)
					CategoryRow(category: "Read More Books", image: "book", users: 13.7)
				}
				.padding()
			}
			.navigationBarTitle("Pre-made Goals")
			.navigationBarTitleDisplayMode(.inline)
		}
	}
}

struct CategoryRow: View {
	let category: String
	let image: String
	let users: Double

	var body: some View {
		NavigationLink(destination: CategoryView(category: category)) {
			HStack {
				Image(systemName: image)
					.font(.title)
					.foregroundColor(.orange)

				VStack(alignment: .leading, spacing: 4) {
					Text(category)
						.font(.title2)
						.fontWeight(.bold)

					Text("\(Int(users))k users")
						.font(.subheadline)
						.foregroundColor(.secondary)
				}

				Spacer()

				Image(systemName: "chevron.right")
					.font(.title3)
					.foregroundColor(.secondary)
			}
			.padding()
			.background(
				RoundedRectangle(cornerRadius: 10)
					.fill(Color(.systemGray6))
			)
		}
	}
}

struct CategoryView: View {
	let category: String

	var body: some View {
		Text("Showing details for \(category)")
			.navigationBarTitle(category, displayMode: .inline)
	}
}

struct Goals_Previews: PreviewProvider {
	static var previews: some View {
		Goals()
	}
}
