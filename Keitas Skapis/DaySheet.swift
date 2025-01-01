//
//  DaySheet.swift
//  Keitas Skapis
//
//  Created by Henrijs Obolevics on 28/12/2024.
//

import SwiftUI
import SwiftData

struct DaySheetView: View {
    // The actual Day object being viewed or edited
    @State var day: Day
    
    @Environment(\.modelContext) private var modelContext // Accesses the data model context for data operations
    @Environment(\.dismiss) private var dismiss // Provides a method to dismiss the current view
    
    @State private var showAddApgerbsSheet = false // Controls the presentation of the AddApgerbsToDayView sheet
    
    // Error handling state variables
    @State private var showErrorAlert = false // Controls the presentation of the error alert
    @State private var errorMessage: String = "" // Stores the error message to display

    var body: some View {
        NavigationStack {
            Form {
                // Section displaying the formatted date
                Section("Datums") {
                    Text(formattedDate(day.date))
                }
                
                // Section displaying associated clothing items
                Section("Apģērbi") {
                    if day.dayClothingItems.isEmpty {
                        // Shows a placeholder text if no clothing items are associated
                        Text("Nav apģērbu.")
                            .foregroundColor(.gray)
                    } else {
                        // Lists all associated clothing items with the ability to delete
                        List {
                            ForEach(day.dayClothingItems, id: \.id) { item in
                                HStack(spacing: 15) {
                                    Text(item.name)
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    AsyncImageView(clothingItem: item) // Displays the clothing item's image
                                        .frame(width: 50, height: 50)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                            .onDelete { offsets in
                                removeClothingItem(at: offsets) // Handles deletion of clothing items
                            }
                        }
                        .frame(minHeight: 50) // Ensures the list has a minimum height
                    }
                }
                
                // Section for adding or editing notes
                Section("Piezīmes") {
                    TextField("Pievienot piezīmes", text: $day.notes) // Allows users to add notes
                }
                
                // Button to present the AddApgerbsToDayView sheet
                Button {
                    showAddApgerbsSheet = true
                } label: {
                    Text("Pievienot Apģērbu")
                        .frame(maxWidth: .infinity) // Makes the button span the full width
                }
                .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2) // Adds a subtle shadow to the button
                
            }
            .navigationTitle("Dienas Pārskats") // Sets the navigation title
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Aizvērt") {
                        dismiss() // Dismisses the current view
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Saglabāt") {
                        saveAndClose() // Saves changes and dismisses the view
                    }
                }
            }
            .sheet(isPresented: $showAddApgerbsSheet) {
                AddApgerbsToDayView(day: $day) // Presents the view to add clothing items
            }
            .onDisappear {
                saveAndClose() // Automatically saves changes when the view disappears
            }
            // Alert for displaying errors
            .alert(isPresented: $showErrorAlert) {
                Alert(
                    title: Text("Kļūda"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    // Formats the given date into a readable string
    private func formattedDate(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        return fmt.string(from: date)
    }

    // Removes a clothing item from the day at the specified offsets
    private func removeClothingItem(at offsets: IndexSet) {
        for index in offsets {
            let item = day.dayClothingItems[index]

            // Remove the item from the current day
            day.dayClothingItems.removeAll { $0.id == item.id }
            item.clothingItemDays.removeAll { $0.id == day.id }

            // Update `lastWorn` after removal
            updateLastWorn(for: item)
        }

        // Save changes to the data context
        do {
            try modelContext.save()
        } catch {
            // Set the error message and show the alert
            errorMessage = "Neizdevās saglabāt izmaiņas. Lūdzu, mēģiniet vēlreiz."
            showErrorAlert = true
        }
    }


    // Updates the `lastWorn` date for a clothing item based on associated days
    private func updateLastWorn(for clothingItem: ClothingItem) {
        // Find the latest valid date in the past or today
        let validDays = clothingItem.clothingItemDays.filter { $0.date <= Date() }
        if let latestDay = validDays.max(by: { $0.date < $1.date }) {
            clothingItem.lastWorn = latestDay.date // Sets to the latest date
        } else {
            // Resets `lastWorn` if no valid days exist
            clothingItem.lastWorn = Date.distantPast
        }
    }


    // Saves changes and dismisses the view
    private func saveAndClose() {
        let hasNotes = !day.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasClothingItems = !day.dayClothingItems.isEmpty
        
        // If the day is already persisted in the data context
        if day.modelContext != nil {
            if !hasNotes && !hasClothingItems {
                modelContext.delete(day) // Remove the day if it's empty
            }
            do {
                try modelContext.save() // Attempt to save changes
                dismiss() // Dismiss the view on successful save
            } catch {
                // Set the error message and show the alert
                errorMessage = "Neizdevās saglabāt izmaiņas. Lūdzu, mēģiniet vēlreiz."
                showErrorAlert = true
            }
            return
        }
        
        // If the day is new and has either notes or clothing items, insert it
        if hasNotes || hasClothingItems {
            modelContext.insert(day)
            do {
                try modelContext.save()
            } catch {
                // Set the error message and show the alert
                errorMessage = "Neizdevās saglabāt dienu. Lūdzu, mēģiniet vēlreiz."
                showErrorAlert = true
                // Optionally, remove the inserted day if save fails
                modelContext.delete(day)
            }
        }
        // If nothing was added, do not insert the day to avoid creating empty entries
        dismiss() // Dismiss the view
    }
}







