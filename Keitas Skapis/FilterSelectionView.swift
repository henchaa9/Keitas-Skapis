
import SwiftUI
import SwiftData

// MARK: - Filtru skats sākumlapā
struct FilterSelectionView: View {
    // MARK: - Filtri
    
    @Binding var selectedColors: Set<CustomColor>
    @Binding var selectedSizes: Set<Int>
    @Binding var selectedSeasons: Set<Season>
    @Binding var selectedLastWorn: Date?
    @Binding var isIronable: Bool?
    @Binding var isWashing: Bool?
    @Binding var isDirty: Bool?
    
    // MARK: - Pieejamās opcijas sarakstiem / izvēles laukiem
    
    let allColors: [CustomColor]
    let allSizes = ["XS", "S", "M", "L", "XL"]
    let allSeasons = Season.allCases
    
    // MARK: - Vides mainīgie
    
    @Environment(\.dismiss) var dismiss
    
    // MARK: - Stāvokļu mainīgie
    @State private var isSeasonDropdownExpanded = false
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Krāsu filtrs
                Section(header: Text("Krāsa")) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))]) {
                        ForEach(allColors, id: \.self) { color in
                            Circle()
                                .fill(color.color)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(selectedColors.contains(color) ? Color.blue : Color.black, lineWidth: selectedColors.contains(color) ? 3 : 1) // Izvēlētā krāsa tiek iezīmēta
                                )
                                .onTapGesture {
                                    toggleColorSelection(color) // Uz pieskāriena izvēlas krāsu/as
                                }
                        }
                    }
                }

                // MARK: - Izmēra filtrs
                Section(header: Text("Izmērs")) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))]) {
                        ForEach(0..<allSizes.count, id: \.self) { index in
                            Text(allSizes[index])
                                .frame(width: 50, height: 30)
                                .background(selectedSizes.contains(index) ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2)) // Izceļ izvēlēto izmēru
                                .cornerRadius(8)
                                .onTapGesture {
                                    toggleSizeSelection(index) // Uz pieskāriena izvēlas izmēru
                                }
                        }
                    }
                }

                // MARK: - Sezonu filtrs (atveras)
                Section(header: Text("Sezona")) {
                    DisclosureGroup(isExpanded: $isSeasonDropdownExpanded) {
                        ForEach(allSeasons, id: \.self) { season in
                            Toggle(season.rawValue, isOn: Binding(
                                get: { selectedSeasons.contains(season) },
                                set: { isSelected in toggleSeasonSelection(season, isSelected: isSelected) }
                            )) // Sezonas izvēle
                        }
                    } label: {
                        Text("Izvēlieties sezonu")
                    }
                }

                // MARK: - Pēdējoreiz vilkts filtrs, atver kalendāru
                Section(header: Text("Pēdējoreiz vilkts")) {
                    DatePicker("Vilkts pirms", selection: Binding(
                        get: { selectedLastWorn ?? Date() },
                        set: { newValue in selectedLastWorn = newValue }
                    ), displayedComponents: .date) // Atzīmē izvēlēto datumu
                }

                // MARK: - Apģērba stāvokļa filtrs tīrs/netīrs/mazgājas
                Section(header: Text("Apģērba stāvoklis")) {
                    Toggle("Gludināms", isOn: Binding(
                        get: { isIronable ?? false },
                        set: { newValue in isIronable = newValue }
                    ))
                    Toggle("Mazgājas", isOn: Binding(
                        get: { isWashing ?? false },
                        set: { newValue in isWashing = newValue }
                    ))
                    Toggle("Netīrs", isOn: Binding(
                        get: { isDirty ?? false },
                        set: { newValue in isDirty = newValue }
                    ))
                }

                // MARK: - Filtru notīrīšanas poga
                Section {
                    Button(action: clearFilters) {
                        Text("Notīrīt filtrus")
                            .foregroundColor(.red)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Filtri")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Aizvērt") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Pielietot") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Palīgfunkcijas

    // Maina krāsas izvēles statusu
    /// - Parameter color: krāsas, kurai mainīt statusu
    private func toggleColorSelection(_ color: CustomColor) {
        if selectedColors.contains(color) {
            selectedColors.remove(color)
        } else {
            selectedColors.insert(color)
        }
    }

    // Maina izmēra izvēles statusu
    /// - Parameter size: izmēra indekss, kuram mainīt statusu
    private func toggleSizeSelection(_ size: Int) {
        if selectedSizes.contains(size) {
            selectedSizes.remove(size)
        } else {
            selectedSizes.insert(size)
        }
    }

    // Maina sezonas izvēles statusu
    /// - Parameters:
    ///   - season: sezona, kurai mainīt statusu
    ///   - isSelected: jaunais statuss
    private func toggleSeasonSelection(_ season: Season, isSelected: Bool) {
        if isSelected {
            selectedSeasons.insert(season)
        } else {
            selectedSeasons.remove(season)
        }
    }

    // Notīra visus filtrus
    private func clearFilters() {
        selectedColors.removeAll()
        selectedSizes.removeAll()
        selectedSeasons.removeAll()
        selectedLastWorn = nil
        isIronable = nil
        isWashing = nil
        isDirty = nil
    }
}

