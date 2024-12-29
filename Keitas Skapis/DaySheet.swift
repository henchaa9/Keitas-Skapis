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
    @State var diena: Diena
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var showAddApgerbsSheet = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Datums") {
                    Text(formattedDate(diena.datums))
                }
                
                
                Section("Apģērbi") {
                    if diena.apgerbi.isEmpty {
                        Text("Nav apģērbu.")
                            .foregroundColor(.gray)
                    } else {
                        List {
                            ForEach(diena.apgerbi, id: \.id) { apgerbs in
                                HStack(spacing: 15) {
                                    Text(apgerbs.nosaukums)
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    AsyncImageView(apgerbs: apgerbs)
                                        .frame(width: 50, height: 50)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                            .onDelete { offsets in
                                removeApgerbs(at: offsets)
                            }
                        }
                        .frame(minHeight: 50)
                    }
                }
                
                Section("Piezīmes") {
                    TextField("Piezīmes", text: $diena.piezimes)
                }
                
                Section {
                    Button("Pievienot Apģērbu") {
                        showAddApgerbsSheet = true
                    }
                }
            }
            .hideKeyboardOnTap()
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
                AddApgerbsToDayView(diena: $diena)
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        return fmt.string(from: date)
    }

    private func removeApgerbs(at offsets: IndexSet) {
        for index in offsets {
            let apg = diena.apgerbi[index]
            // 1) remove from day
            diena.apgerbi.removeAll { $0 == apg }
            // 2) also remove from apg.dienas to keep the relationship in sync
            apg.dienas.removeAll { $0 == diena }
        }
    }

    private func saveAndClose() {
        let hasNotes   = !diena.piezimes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasApgerbi = !diena.apgerbi.isEmpty
        
        // If it’s already in DB
        if diena.modelContext != nil {
            if !hasNotes && !hasApgerbi {
                modelContext.delete(diena) // remove empty day
            }
            try? modelContext.save()
            dismiss()
            return
        }
        
        // Otherwise, brand new ephemeral day
        if hasNotes || hasApgerbi {
            modelContext.insert(diena)
            try? modelContext.save()
        }
        // If nothing was added, do not insert => no leftover day
        
        dismiss()
    }


}




