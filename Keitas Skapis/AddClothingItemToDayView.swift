
import SwiftUI
import SwiftData

// MARK: - Skats, kurā kalendāra dienai var pievienot apģērbus
struct AddClothingItemToDayView: View {
    // MARK: - Dienas objekts, kuru jārediģē
    @Binding var day: Day

    // MARK: - Datu vaicājumi un vides mainīgie
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allClothingItems: [ClothingItem]

    // MARK: - Kļūdu apstrādes mainīgie
    @State private var showErrorAlert = false
    @State private var errorMessage: String = ""

    var body: some View {
        NavigationStack {
            List {
                // Saraksts ar apģērbiem
                ForEach(allClothingItems, id: \.id) { item in
                    Button {
                        toggleClothingItem(item) // Poga apģērba pievienošanai dienai
                    } label: {
                        HStack {
                            // Vizuāls apstiprinājums, ka apģērbs ir/nav pievienots dienai
                            if day.dayClothingItems.contains(item) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            // Apģērba nosaukums un asinhrons attēls
                            Text(item.name)
                                .font(.headline)

                            Spacer()

                            AsyncImageView(clothingItem: item)
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

    // Pievieno/noņem apģērbu dienai
    /// - Parameter clothingItem: apģērbs, kurš tiek pievienots/noņemts
    private func toggleClothingItem(_ clothingItem: ClothingItem) {
        if day.dayClothingItems.contains(clothingItem) {
            // Noņem apģērbu no dienas
            if let index = day.dayClothingItems.firstIndex(where: { $0.id == clothingItem.id }) {
                day.dayClothingItems.remove(at: index)
            }

            // Noņem dienas referenci no apģērba
            if let index = clothingItem.clothingItemDays.firstIndex(where: { $0.id == day.id }) {
                clothingItem.clothingItemDays.remove(at: index)
            }

            // Atjaunina apģērba `lastWorn` jeb pēdējoreiz vilkts pēc izmaiņām
            updateLastWorn(for: clothingItem)
        } else {
            // Pievieno apģērbu dienai
            if !day.dayClothingItems.contains(clothingItem) {
                day.dayClothingItems.append(clothingItem)
            }
            if !clothingItem.clothingItemDays.contains(day) {
                clothingItem.clothingItemDays.append(day)
            }
        }

        // Mēģina saglabāt
        do {
            try modelContext.save()
        } catch {
            // Kļūdu apstrāde
            errorMessage = "Neizdevās saglabāt izmaiņas"
            showErrorAlert = true
        }
    }

    /// Atjaunina `lastWorn` jeb pēdējoreiz vilkts apģērbam balstoties uz piesasistītajām dienām
    /// - Parameter clothingItem: apģērbs, kuram jāmaina lastWorn
    private func updateLastWorn(for clothingItem: ClothingItem) {
        // Dienas, kas ir pagātnē vai šodien
        let validDays = clothingItem.clothingItemDays.filter { $0.date <= Date() }
        if let latestDay = validDays.max(by: { $0.date < $1.date }) {
            clothingItem.lastWorn = latestDay.date // Atjaunina uz tuvāko piesaistīto dienu
        } else {
            // Atgriež `lastWorn` ja nav atbilstošu dienu
            clothingItem.lastWorn = Date.distantPast
        }
    }
}


