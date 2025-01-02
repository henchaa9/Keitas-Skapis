
import SwiftUI
import SwiftData

// MARK: - Skats, uzspiežot uz dienas kalendārā
struct DaySheetView: View {
    // MARK: - Dienas objekts
    @State var day: Day
    
    // MARK: - Vides mainīgie
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Stāvokļu mainīgie
    @State private var showAddApgerbsSheet = false
    
    // MARK: - Kļūdu apstrādes mainīgie
    @State private var showErrorAlert = false
    @State private var errorMessage: String = ""

    var body: some View {
        NavigationStack {
            Form {
                // Datums
                Section("Datums") {
                    Text(formattedDate(day.date))
                }
                
                // Sadaļa, kurā redzami attiecīgās dienas apģērbi
                Section("Apģērbi") {
                    if day.dayClothingItems.isEmpty {
                        // Noklusējuma teksts, ja dienai nav pievienotu apģērbu
                        Text("Nav apģērbu.")
                            .foregroundColor(.gray)
                    } else {
                        // Saraksts, kas ģenerē apģērbus
                        List {
                            ForEach(day.dayClothingItems, id: \.id) { item in
                                HStack(spacing: 15) {
                                    Text(item.name)
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    AsyncImageView(clothingItem: item) // Apģērba attēls tiek lādēts asinhroni
                                        .frame(width: 50, height: 50)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                            .onDelete { offsets in
                                removeClothingItem(at: offsets) // Apģērba dzēšana
                            }
                        }
                        .frame(minHeight: 50)
                    }
                }
                
                // Piezīmju sadaļa
                Section("Piezīmes") {
                    TextField("Pievienot piezīmes", text: $day.notes)
                }
                
                // Poga, kas atver skatu, kurā dienai var pievienot apģērbus
                Button {
                    showAddApgerbsSheet = true
                } label: {
                    Text("Pievienot Apģērbu")
                        .frame(maxWidth: .infinity)
                }
                .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                
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
                        saveAndClose() // Saglabāšana var notikt manuāli, kā arī pie .onDissapear automātiski
                    }
                }
            }
            .sheet(isPresented: $showAddApgerbsSheet) {
                AddClothingItemToDayView(day: $day) // Lapa, kurā dienai var pievienot apģērbus
            }
            .onDisappear {
                saveAndClose() // Automātiska saglabāšana, aizverot dienu
            }
            // Kļūdu apstrāde
            .alert(isPresented: $showErrorAlert) {
                Alert(
                    title: Text("Kļūda"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    // Formatē datumu simbolu virknē
    private func formattedDate(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        return fmt.string(from: date)
    }

    // Noņem apģērbu no dienas
    private func removeClothingItem(at offsets: IndexSet) {
        for index in offsets {
            let item = day.dayClothingItems[index]

            // Noņem referenci abos galos, t.i., dienas apģērbus un apģērba dienas
            day.dayClothingItems.removeAll { $0.id == item.id }
            item.clothingItemDays.removeAll { $0.id == day.id }

            // Atjaunina apģērba lasWorn jeb pēdējoreiz vilkts parametru
            updateLastWorn(for: item)
        }

        // Saglabā izmaiņas
        do {
            try modelContext.save()
        } catch {
            // Kļūdu apstrāde
            errorMessage = "Neizdevās saglabāt izmaiņas. Lūdzu, mēģiniet vēlreiz."
            showErrorAlert = true
        }
    }


    // Atjaunina apģērba lastWorn jeb pēdējoreiz vilkts balstoties uz apģērbam asociētajām dienām
    private func updateLastWorn(for clothingItem: ClothingItem) {
        // Atrod tuvāko dienu, kad apģērbs patiešām ir vilkts
        // Piemēram, ja apģērbs tiek pievienots senākam datumam, parametrs netiek atjaunināts
        // Tāpat arī, pievienojot nākotnes datumam, tas atjauninās tikai tad, kad datums pienāk
        let validDays = clothingItem.clothingItemDays.filter { $0.date <= Date() }
        if let latestDay = validDays.max(by: { $0.date < $1.date }) {
            clothingItem.lastWorn = latestDay.date // Sets to the latest date
        } else {
            // Resets `lastWorn` if no valid days exist
            clothingItem.lastWorn = Date.distantPast
        }
    }


    // Saglabā izmaiņas un aizver lapu
    private func saveAndClose() {
        let hasNotes = !day.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasClothingItems = !day.dayClothingItems.isEmpty
        
        // Ja diena jau eksistē
        if day.modelContext != nil {
            if !hasNotes && !hasClothingItems {
                modelContext.delete(day) // Noņem, ja diena ir tukša (tiek izdzēsti dati)
            }
            do {
                try modelContext.save() // Mēģina saglabāt
                dismiss() // Aizver lapu
            } catch {
                // Kļūdu apstrāde
                errorMessage = "Neizdevās saglabāt izmaiņas. Lūdzu, mēģiniet vēlreiz."
                showErrorAlert = true
            }
            return
        }
        
        // Ja diena ir tikko izveidota un tai pievienoti apģērbi un/vai piezīmes, saglabā to
        if hasNotes || hasClothingItems {
            modelContext.insert(day)
            do {
                try modelContext.save()
            } catch {
                // Kļūdu apstrāde
                errorMessage = "Neizdevās saglabāt dienu. Lūdzu, mēģiniet vēlreiz."
                showErrorAlert = true
                // Ja iestājas kļūda, noņem dienu
                modelContext.delete(day)
            }
        }
        // Ja nekas netiek pievienots, aizver lapu
        dismiss()
    }
}







