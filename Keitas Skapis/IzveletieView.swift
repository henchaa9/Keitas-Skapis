//
//  IzveletieView.swift
//  Keitas Skapis
//
//  Created by Henrijs Obolevics on 27/12/2024.
//

import SwiftUI
import SwiftData

struct IzveletieView: View {
    // Access the shared ChosenManager from the environment
    @EnvironmentObject private var chosenManager: ChosenManager
    // Access the data model context for database operations
    @Environment(\.modelContext) private var modelContext
    // Access the dismiss action to close the view
    @Environment(\.dismiss) private var dismiss

    // State properties to manage user inputs
    @State private var selectedDate: Date = Date()
    @State private var notes: String = ""
    
    // Query to fetch all Day entities from the data model
    @Query private var days: [Day]

    var body: some View {
        NavigationStack {
            Form {
                // Section for displaying chosen clothing items
                Section("") {
                    if chosenManager.chosenClothingItems.isEmpty {
                        // Message displayed when no clothes are selected
                        Text("Nav izvēlētu apģērbu.")
                    } else {
                        // List each selected clothing item with its image and name
                        ForEach(chosenManager.chosenClothingItems, id: \.id) { clothingItem in
                            HStack(spacing: 15) {
                                Text(clothingItem.name)
                                    .font(.headline)
                                
                                Spacer()
                                
                                // Asynchronously load and display the clothing item's image
                                AsyncImageView(clothingItem: clothingItem)
                                    .frame(width: 50, height: 50)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        // Enable swipe-to-delete functionality
                        .onDelete(perform: removeFromChosen) // Helper Function
                    }
                }

                // Section for selecting a date
                Section {
                    DatePicker("Izvēlēties datumu", selection: $selectedDate, displayedComponents: .date)
                }

                // Section for adding notes
                Section("Piezīmes") {
                    TextField("Pievienot piezīmes", text: $notes)
                }
                
                // Confirmation button to save the selected clothes and notes
                Button {
                    Confirm() // Helper Function
                } label: {
                    Text("Apstiprināt")
                }
                .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Izvēlētie apģērbi") // Set the navigation title
            .toolbar {
                // Toolbar item to close the view
                ToolbarItem(placement: .cancellationAction) {
                    Button("Aizvērt") {
                        dismiss() // Dismiss the current view
                    }
                }
            }
        }
    }

    // MARK: - Helper Functions

    /// Removes selected clothing items from the chosen list.
    /// - Parameter offsets: The set of indices to remove.
    private func removeFromChosen(at offsets: IndexSet) {
        for index in offsets {
            let clothingItem = chosenManager.chosenClothingItems[index]
            chosenManager.remove(clothingItem)
        }
    }
    
    /// Confirms and saves the selected clothing items, date, and notes.
    private func Confirm() {
        // Ensure there are selected items or notes before proceeding
        guard !chosenManager.chosenClothingItems.isEmpty || !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            dismiss()
            return
        }

        let currentDay: Day
        // Check if a Day entity with the selected date already exists
        if let existingDay = days.first(where: { sameDate($0.date, selectedDate) }) {
            currentDay = existingDay
        } else {
            // Create a new Day entity if none exists for the selected date
            let newDay = Day(date: selectedDate, notes: notes)
            modelContext.insert(newDay) // Insert new day into context
            try? modelContext.save()   // Save immediately to assign an ID
            currentDay = newDay
        }

        // Associate chosen clothing items with the current day
        for item in chosenManager.chosenClothingItems {
            if !currentDay.dayClothingItems.contains(item) {
                currentDay.dayClothingItems.append(item)
            }
            if !item.clothingItemDays.contains(currentDay) {
                item.clothingItemDays.append(currentDay)
            }

            // Update `lastWorn` date if the selected date is today or earlier
            if selectedDate <= Date() {
                item.lastWorn = max(item.lastWorn, selectedDate)
            }
        }

        // Append notes to the day's existing notes
        if !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            currentDay.notes += currentDay.notes.isEmpty ? notes : "\n\(notes)"
        }

        // Attempt to save all changes to the data model
        do {
            try modelContext.save()
            chosenManager.clear() // Clear the chosen items after saving
            dismiss()             // Close the view
        } catch {
            print("Failed to save changes: \(error)")
        }
    }

    /// Checks if two dates fall on the same calendar day.
    /// - Parameters:
    ///   - d1: The first date.
    ///   - d2: The second date.
    /// - Returns: `true` if both dates are on the same day; otherwise, `false`.
    private func sameDate(_ d1: Date, _ d2: Date) -> Bool {
        Calendar.current.isDate(d1, inSameDayAs: d2)
    }
}



