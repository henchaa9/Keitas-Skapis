//
//  AddApgerbsToDayView.swift
//  Keitas Skapis
//
//  Created by Henrijs Obolevics on 28/12/2024.
//

import SwiftUI
import SwiftData

struct AddApgerbsToDayView: View {
    @Binding var day: Day

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var allClothingItems: [ClothingItem]

    var body: some View {
        NavigationStack {
            List {
                ForEach(allClothingItems, id: \.id) { item in
                    Button {
                        toggleClothingItem(item)
                    } label: {
                        HStack {
                            // Indicate if it's in the day
                            if day.dayClothingItems.contains(item) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            // Show some image + name
                            Text(item.name)
                                .font(.headline)

                            Spacer()

                            AsyncImageView(clothingItem: item)
                                .frame(width: 40, height: 40)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
            .navigationTitle("Pievienot Apģērbu")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Aizvērt") {
                        dismiss()
                    }
                }
            }
        }
    }

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

        // Save changes
        do {
            try modelContext.save()
        } catch {
            print("Failed to save changes: \(error)")
        }
    }


    private func updateLastWorn(for clothingItem: ClothingItem) {
        // Find the latest past or today's date from associated days
        let validDays = clothingItem.clothingItemDays.filter { $0.date <= Date() }
        if let latestDay = validDays.max(by: { $0.date < $1.date }) {
            clothingItem.lastWorn = latestDay.date
        } else {
            // Reset `lastWorn` if no valid days remain
            clothingItem.lastWorn = Date.distantPast
        }
    }



}

