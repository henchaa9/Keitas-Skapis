//
//  AddApgerbsToDayView.swift
//  Keitas Skapis
//
//  Created by Henrijs Obolevics on 28/12/2024.
//

import SwiftUI
import SwiftData

struct AddApgerbsToDayView: View {
    @Binding var day: Day // Binding to the Day object being edited

    @Environment(\.modelContext) private var modelContext // Accesses the data model context for data operations
    @Environment(\.dismiss) private var dismiss // Provides a method to dismiss the current view

    @Query private var allClothingItems: [ClothingItem] // Fetches all ClothingItem entities from the data store

    // Error handling state variables
    @State private var showErrorAlert = false // Controls the presentation of the error alert
    @State private var errorMessage: String = "" // Stores the error message to display

    var body: some View {
        NavigationStack {
            List {
                // Iterate over all clothing items to display them in the list
                ForEach(allClothingItems, id: \.id) { item in
                    Button {
                        toggleClothingItem(item) // Toggle the inclusion of the clothing item in the day
                    } label: {
                        HStack {
                            // Indicate if the clothing item is already associated with the day
                            if day.dayClothingItems.contains(item) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            // Display the name of the clothing item
                            Text(item.name)
                                .font(.headline)

                            Spacer()

                            // Display the clothing item's image asynchronously
                            AsyncImageView(clothingItem: item)
                                .frame(width: 40, height: 40)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
            .navigationTitle("Pievienot Apģērbu") // Sets the navigation title
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Aizvērt") {
                        dismiss() // Dismisses the current view
                    }
                }
            }
            // Present the error alert when an error occurs
            .alert(isPresented: $showErrorAlert) {
                Alert(
                    title: Text("Kļūda"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    /// Toggles the inclusion of a clothing item in the day
    /// - Parameter clothingItem: The ClothingItem to toggle
    private func toggleClothingItem(_ clothingItem: ClothingItem) {
        if day.dayClothingItems.contains(clothingItem) {
            // Remove the clothing item from the current day
            if let index = day.dayClothingItems.firstIndex(where: { $0.id == clothingItem.id }) {
                day.dayClothingItems.remove(at: index)
            }

            // Remove the association with this day from the clothing item
            if let index = clothingItem.clothingItemDays.firstIndex(where: { $0.id == day.id }) {
                clothingItem.clothingItemDays.remove(at: index)
            }

            // Update `lastWorn` after removing the association
            updateLastWorn(for: clothingItem)
        } else {
            // Add the clothing item to the current day
            if !day.dayClothingItems.contains(clothingItem) {
                day.dayClothingItems.append(clothingItem)
            }
            if !clothingItem.clothingItemDays.contains(day) {
                clothingItem.clothingItemDays.append(day)
            }
        }

        // Attempt to save changes to the data context
        do {
            try modelContext.save()
        } catch {
            // Set the error message and trigger the error alert
            errorMessage = "Neizdevās saglabāt izmaiņas. Lūdzu, mēģiniet vēlreiz."
            showErrorAlert = true
        }
    }

    /// Updates the `lastWorn` date for a clothing item based on associated days
    /// - Parameter clothingItem: The ClothingItem to update
    private func updateLastWorn(for clothingItem: ClothingItem) {
        // Filter for days that are in the past or today
        let validDays = clothingItem.clothingItemDays.filter { $0.date <= Date() }
        if let latestDay = validDays.max(by: { $0.date < $1.date }) {
            clothingItem.lastWorn = latestDay.date // Update to the latest associated day
        } else {
            // Reset `lastWorn` if no valid days remain
            clothingItem.lastWorn = Date.distantPast
        }
    }
}


