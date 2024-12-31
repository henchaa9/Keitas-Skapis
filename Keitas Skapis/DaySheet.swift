//
//  DaySheet.swift
//  Keitas Skapis
//
//  Created by Henrijs Obolevics on 28/12/2024.
//

import SwiftUI
import SwiftData

struct DaySheetView: View {
    // The actual Diena object
    @State var day: Day
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var showAddApgerbsSheet = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Datums") {
                    Text(formattedDate(day.date))
                }
                
                Section("Apģērbi") {
                    if day.dayClothingItems.isEmpty {
                        Text("Nav apģērbu.")
                            .foregroundColor(.gray)
                    } else {
                        List {
                            ForEach(day.dayClothingItems, id: \.id) { item in
                                HStack(spacing: 15) {
                                    Text(item.name)
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    AsyncImageView(clothingItem: item)
                                        .frame(width: 50, height: 50)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                            .onDelete { offsets in
                                removeClothingItem(at: offsets)
                            }
                        }
                        .frame(minHeight: 50)
                    }
                }
                
                Section("Piezīmes") {
                    TextField("Pievienot piezīmes", text: $day.notes)
                }
                
//                Section {
//                    Button("Pievienot Apģērbu") {
//                        showAddApgerbsSheet = true
//                    }
//                }
                Button {
                    showAddApgerbsSheet = true
                } label: {
                    Text("Pievienot Apģērbu").frame(maxWidth: .infinity)
                }.shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                
            }
            .navigationTitle("Dienas Pārskats")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Aizvērt") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Saglabāt") {
                        saveAndClose()
                    }
                }
            }
            .sheet(isPresented: $showAddApgerbsSheet) {
                AddApgerbsToDayView(day: $day)
            }
            .onDisappear {
                saveAndClose() // Autosave when the view disappears
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        return fmt.string(from: date)
    }

    private func removeClothingItem(at offsets: IndexSet) {
        for index in offsets {
            let item = day.dayClothingItems[index]

            // Remove the item from the current day
            day.dayClothingItems.removeAll { $0.id == item.id }
            item.clothingItemDays.removeAll { $0.id == day.id }

            // Update `lastWorn` after removal
            updateLastWorn(for: item)
        }

        // Save changes
        do {
            try modelContext.save()
        } catch {
            print("Failed to save changes: \(error)")
        }
    }


    private func updateLastWorn(for clothingItem: ClothingItem) {
        // Find the latest valid date in the past or today
        let validDays = clothingItem.clothingItemDays.filter { $0.date <= Date() }
        if let latestDay = validDays.max(by: { $0.date < $1.date }) {
            clothingItem.lastWorn = latestDay.date
        } else {
            // Reset `lastWorn` if no valid days exist
            clothingItem.lastWorn = Date.distantPast
        }
    }


    private func saveAndClose() {
        let hasNotes   = !day.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasClothingItems = !day.dayClothingItems.isEmpty
        
        // If it’s already in DB
        if day.modelContext != nil {
            if !hasNotes && !hasClothingItems {
                modelContext.delete(day) // remove empty day
            }
            try? modelContext.save()
            dismiss()
            return
        }
        
        // Otherwise, brand new ephemeral day
        if hasNotes || hasClothingItems {
            modelContext.insert(day)
            try? modelContext.save()
        }
        // If nothing was added, do not insert => no leftover day
        dismiss()
    }
}





