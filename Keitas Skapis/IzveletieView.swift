//
//  IzveletieView.swift
//  Keitas Skapis
//
//  Created by Henrijs Obolevics on 27/12/2024.
//

import SwiftUI
import SwiftData


struct IzveletieView: View {
    @EnvironmentObject private var chosenManager: ChosenManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDate: Date = Date()
    @State private var notes: String = ""
    
    @Query private var days: [Day]

    var body: some View {
        NavigationStack {
            Form {
                Section("") {
                    if chosenManager.chosenClothingItems.isEmpty {
                        Text("Nav izvēlētu apģērbu.")
                    } else {
                        // Display each chosen Apgerbs with image + name in an HStack
                        ForEach(chosenManager.chosenClothingItems, id: \.id) { clothingItem in
                            HStack(spacing: 15) {
                                Text(clothingItem.name)
                                    .font(.headline)
                                
                                Spacer()
                                
                                AsyncImageView(clothingItem: clothingItem)
                                    .frame(width: 50, height: 50)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        .onDelete(perform: removeFromChosen)
                    }
                }

                Section {
                    DatePicker("Izvēlēties datumu", selection: $selectedDate, displayedComponents: .date)
                }

                Section("Piezīmes") {
                    TextField("Pievienot piezīmes", text: $notes)
                }
                
                Button {
                    Confirm()
                } label: {
                    Text("Apstiprināt")
                }.shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2).frame(maxWidth: .infinity)

            }
            .navigationTitle("Izvēlētie apģērbi")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Aizvērt") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func removeFromChosen(at offsets: IndexSet) {
        for index in offsets {
            let clothingItem = chosenManager.chosenClothingItems[index]
            chosenManager.remove(clothingItem)
        }
    }
    

    private func Confirm() {
        guard !chosenManager.chosenClothingItems.isEmpty || !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            dismiss()
            return
        }

        let currentDay: Day
        if let existingDay = days.first(where: { sameDate($0.date, selectedDate) }) {
            currentDay = existingDay
        } else {
            let newDay = Day(date: selectedDate, notes: notes)
            modelContext.insert(newDay) // Insert new day into context
            try? modelContext.save()   // Save immediately to assign an ID
            currentDay = newDay
        }

        // Add chosen clothing items and update relationships
        for item in chosenManager.chosenClothingItems {
            if !currentDay.dayClothingItems.contains(item) {
                currentDay.dayClothingItems.append(item)
            }
            if !item.clothingItemDays.contains(currentDay) {
                item.clothingItemDays.append(currentDay)
            }

            // Update `lastWorn` only if the date is today or earlier
            if selectedDate <= Date() {
                item.lastWorn = max(item.lastWorn, selectedDate)
            }
        }

        // Add notes to the day
        if !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            currentDay.notes += currentDay.notes.isEmpty ? notes : "\n\(notes)"
        }

        // Save changes
        do {
            try modelContext.save()
            chosenManager.clear()
            dismiss()
        } catch {
            print("Failed to save changes: \(error)")
        }
    }



    
    private func sameDate(_ d1: Date, _ d2: Date) -> Bool {
        Calendar.current.isDate(d1, inSameDayAs: d2)
    }
}


