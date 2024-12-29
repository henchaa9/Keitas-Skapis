//
//  AddApgerbsToDayView.swift
//  Keitas Skapis
//
//  Created by Henrijs Obolevics on 28/12/2024.
//

import SwiftUI
import SwiftData

struct AddApgerbsToDayView: View {
    @Binding var diena: Diena

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

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

                            Spacer()

                            // Show some image + name
                            Text(apgerbs.nosaukums)
                                .font(.headline)

                            Spacer()

                            AsyncImageView(apgerbs: apgerbs)
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

    private func toggleApgerbs(_ apgerbs: Apgerbs) {
        if diena.apgerbi.contains(apgerbs) {
            // Remove from day
            diena.apgerbi.removeAll { $0 == apgerbs }
            apgerbs.dienas.removeAll { $0 == diena }
        } else {
            // Add to day
            diena.apgerbi.append(apgerbs)
            if !apgerbs.dienas.contains(diena) {
                apgerbs.dienas.append(diena)
            }

            // Update `pedejoreizVilkts` only if the day’s date is later than the current value
            if diena.datums > apgerbs.pedejoreizVilkts {
                apgerbs.pedejoreizVilkts = diena.datums
            }
        }

        // Save changes
        try? modelContext.save()
    }
}

