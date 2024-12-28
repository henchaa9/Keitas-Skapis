//
//  AddApgerbsToDayView.swift
//  Keitas Skapis
//
//  Created by Henrijs Obolevics on 28/12/2024.
//

import SwiftUI
import SwiftData

struct AddApgerbsToDayView: View {
    // We reference the same day from DaySheetView
    @Binding var diena: Diena
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // Query all Apgerbs
    @Query private var allApgerbs: [Apgerbs]

    var body: some View {
        NavigationStack {
            List {
                ForEach(allApgerbs, id: \.id) { apgerbs in
                    Button {
                        toggleApgerbs(apgerbs)
                    } label: {
                        HStack {
                            // Indicate if it's in the day
                            if diena.apgerbi.contains(apgerbs) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.gray)
                            }
                            
                            // Show some image + name
                            AsyncImageView(apgerbs: apgerbs)
                                .frame(width: 40, height: 40)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            Text(apgerbs.nosaukums)
                                .font(.headline)
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
    
    private func toggleApgerbs(_ apgerbs: Apgerbs) {
        // If the apgerbs is already in the day, remove it. Otherwise add it.
        if diena.apgerbi.contains(apgerbs) {
            // Remove from day
            diena.apgerbi.removeAll { $0 == apgerbs }
            // Remove from apgerbs
            apgerbs.dienas.removeAll { $0 == diena }
        } else {
            // Add to day
            diena.apgerbi.append(apgerbs)
            // Also add day to apgerbs
            if !apgerbs.dienas.contains(diena) {
                apgerbs.dienas.append(diena)
            }
        }
        
        // Optionally save right away, or wait until user presses “Saglabāt” in DaySheetView
        try? modelContext.save()
    }
}

