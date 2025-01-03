
import SwiftUI
import SwiftData

// MARK: - Izvēlēto apģerbu skats
struct chosenClothingItemsView: View {
    // MARK: - Vides mainīgie un datu vaicājumi
    @EnvironmentObject private var chosenManager: ChosenManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var days: [Day]

    // MARK: - Stāvokļu mainīgie
    @State private var selectedDate: Date = Date()
    @State private var notes: String = ""

    // MARK: - Kļūdu apstrādes mainīgie
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        NavigationStack {
            Form {
                // Izvēlēto apģērbu sadaļa
                Section("") {
                    if chosenManager.chosenClothingItems.isEmpty {
                        // Noklusējuma ziņa
                        Text("Nav izvēlētu apģērbu.")
                    } else {
                        // Katrs attēls parādīts ar attēlu un nosaukumu
                        ForEach(chosenManager.chosenClothingItems, id: \.id) { clothingItem in
                            HStack(spacing: 15) {
                                Text(clothingItem.name)
                                    .font(.headline)
                                
                                Spacer()
                                
                                // Asinhroni ielādē attēlu
                                AsyncImageView(clothingItem: clothingItem)
                                    .frame(width: 50, height: 50)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        // Pavilkšana izdzēš attēlu
                        .onDelete(perform: removeFromChosen)
                    }
                }

                // Datuma izvēle
                Section {
                    DatePicker("Izvēlēties datumu", selection: $selectedDate, displayedComponents: .date)
                }

                // Piezīmes
                Section("Piezīmes") {
                    TextField("Pievienot piezīmes", text: $notes)
                }
                
                // Apstiprināšanas poga
                Button {
                    Confirm()
                } label: {
                    Text("Apstiprināt")
                }
                .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Izvēlētie apģērbi")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Aizvērt") {
                        dismiss() // Dismiss the current view
                    }
                }
            }
            .alert(isPresented: $showErrorAlert) { // Added alert modifier
                Alert(
                    title: Text("Kļūda"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    // MARK: - Palīgfunkcijas

    // Noņem apģērbu no izvēlēto saraksta
    /// - Parameter offsets: indeksi, kurus noņemt
    private func removeFromChosen(at offsets: IndexSet) {
        for index in offsets {
            let clothingItem = chosenManager.chosenClothingItems[index]
            chosenManager.remove(clothingItem)
        }
    }
    
    // Saglabā izvēlētos apģērbus norādītajam datumam ar piezīmēm
    private func Confirm() {
        // Pārbauda vai ir izvēlēti apģērbi un/vai piezīmes
        guard !chosenManager.chosenClothingItems.isEmpty || !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            dismiss()
            return
        }

        let currentDay: Day
        var isNewDay = false

        // Pārbauda, vai attiecīgās dienas objekts jau neeksistē
        if let existingDay = days.first(where: { sameDate($0.date, selectedDate) }) {
            currentDay = existingDay
        } else {
            // Izveido jaunu dienu, bez piezīmēm
            let newDay = Day(date: selectedDate)
            modelContext.insert(newDay)
            do {
                try modelContext.save()
                currentDay = newDay
                isNewDay = true
            } catch {
                // Kļūdas pārvaldība
                errorMessage = "Neizdevās saglabāt jauno dienu."
                showErrorAlert = true
                return
            }
        }

        // Asociē dienu ar apģērbiem
        for item in chosenManager.chosenClothingItems {
            if !currentDay.dayClothingItems.contains(item) {
                currentDay.dayClothingItems.append(item)
            }
            if !item.clothingItemDays.contains(currentDay) {
                item.clothingItemDays.append(currentDay)
            }

            // Atjaunina `lastWorn` ja izvēlētais datums ir šodien vai agrāk
            if selectedDate <= Date() {
                item.lastWorn = max(item.lastWorn, selectedDate)
            }
        }

        // Pievieno piezīmes tikai, ja diena nav jauna
        if !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isNewDay {
            currentDay.notes += currentDay.notes.isEmpty ? notes : "\n\(notes)"
        } else if isNewDay && !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // Set notes for new day
            currentDay.notes = notes
        }

        // Mēģina saglabāt
        do {
            try modelContext.save()
            chosenManager.clear()
            dismiss()
        } catch {
            // Kļūdas pārvaldība
            errorMessage = "Neizdevās saglabāt izmaiņas."
            showErrorAlert = true
        }
    }

    

    // Pārbauda, vai divi datumi iekrīt vienā dienā
    /// - Parameters:
    ///   - d1: pirmais datums
    ///   - d2: otrais datums
    /// - Returns: `true` , ja datumi vienādi, pretēji `false`.
    private func sameDate(_ d1: Date, _ d2: Date) -> Bool {
        Calendar.current.isDate(d1, inSameDayAs: d2)
    }
}




