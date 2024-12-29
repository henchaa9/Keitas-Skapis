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
    @State private var piezimes: String = ""
    
    @Query private var dienas: [Diena]

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Apģērbi")) {
                    if chosenManager.chosenApgerbi.isEmpty {
                        Text("Nav izvēlētu apģērbu.")
                    } else {
                        // Display each chosen Apgerbs with image + name in an HStack
                        ForEach(chosenManager.chosenApgerbi, id: \.id) { apgerbs in
                            HStack(spacing: 15) {
                                Text(apgerbs.nosaukums)
                                    .font(.headline)
                                
                                Spacer()
                                
                                AsyncImageView(apgerbs: apgerbs)
                                    .frame(width: 50, height: 50)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        .onDelete(perform: removeFromChosen)
                    }
                }

                Section(header: Text("Datums")) {
                    DatePicker("Izvēlēties datumu", selection: $selectedDate, displayedComponents: .date)
                }

                Section(header: Text("Piezīmes")) {
                    TextField("Pievienot piezīmes", text: $piezimes)
                }

                Section {
                    Button("Apstiprināt") {
                        apstiprinat()
                    }
                }
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
            let apgerbs = chosenManager.chosenApgerbi[index]
            chosenManager.remove(apgerbs)
        }
    }

    private func apstiprinat() {
        // Check if there are no chosen items and no notes
        if chosenManager.chosenApgerbi.isEmpty && piezimes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            dismiss()
            return
        }

        // 1) Check if there's a day already in DB for `selectedDate`
        if let existingDay = dienas.first(where: { sameDate($0.datums, selectedDate) }) {
            // Add the chosen Apgerbs to the existing day
            for apg in chosenManager.chosenApgerbi {
                if !existingDay.apgerbi.contains(apg) {
                    existingDay.apgerbi.append(apg)
                }
                if !apg.dienas.contains(existingDay) {
                    apg.dienas.append(existingDay)
                }

                // Update `pedejoreizVilkts` if the selected date is later
                if selectedDate > apg.pedejoreizVilkts {
                    apg.pedejoreizVilkts = selectedDate
                }
            }

            // Append the new text to existing notes if not empty
            if !piezimes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                existingDay.piezimes += "\n\(piezimes)"
            }

            // Save changes
            try? modelContext.save()
        } else {
            // 2) No day exists => create a new one
            let newDiena = Diena(datums: selectedDate, piezimes: piezimes)
            
            for apg in chosenManager.chosenApgerbi {
                newDiena.apgerbi.append(apg)
                apg.dienas.append(newDiena)

                // Update `pedejoreizVilkts` if the selected date is later
                if selectedDate > apg.pedejoreizVilkts {
                    apg.pedejoreizVilkts = selectedDate
                }
            }
            
            // Insert the new day into the model context and save
            modelContext.insert(newDiena)
            try? modelContext.save()
        }
        
        // 3) Clear the cart + dismiss
        chosenManager.clear()
        dismiss()
    }

    
    private func sameDate(_ d1: Date, _ d2: Date) -> Bool {
        Calendar.current.isDate(d1, inSameDayAs: d2)
    }
}


