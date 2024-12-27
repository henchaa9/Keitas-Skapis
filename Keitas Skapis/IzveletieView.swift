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

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Izvēlētie Apģērbi")) {
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
                    TextField("Pievieno piezīmes", text: $piezimes)
                }

                Section {
                    Button("Apstiprināt") {
                        apstiprinat()
                    }
                }
            }
            .navigationTitle("Izvēlētie")
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
        // Create or fetch a Diena for the chosen date
        let newDiena = Diena(datums: selectedDate, piezimes: piezimes)
        // Add the chosen Apgerbs
        for apgerbs in chosenManager.chosenApgerbi {
            newDiena.apgerbi.append(apgerbs)
        }
        
        // Insert + save
        modelContext.insert(newDiena)
        try? modelContext.save()

        // Clear + dismiss
        chosenManager.clear()
        dismiss()
    }
}


