//
//  FilterSelectionView.swift
//  Keitas Skapis
//
//  Created by Henrijs Obolevics on 30/12/2024.
//

import SwiftUI

struct FilterSelectionView: View {
    @Binding var selectedColors: Set<CustomColor> // For color filtering
    @Binding var selectedSizes: Set<Int> // For size filtering
    @Binding var selectedSeasons: Set<Season> // For season filtering
    @Binding var selectedLastWorn: Date? // For last worn filtering
    @Binding var isIronable: Bool? // For `gludinams`
    @Binding var isWashing: Bool? // For `mazgajas`
    @Binding var isDirty: Bool? // For `netirs`

    let allColors: [CustomColor] // Static list of colors based on unfiltered Apgerbs
    let allSizes = ["XS", "S", "M", "L", "XL"]
    let allSeasons = Season.allCases

    @Environment(\.dismiss) var dismiss
    @State private var isSeasonDropdownExpanded = false

    var body: some View {
        NavigationStack {
            Form {
                // Colors Filter
                Section(header: Text("Krāsa")) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))]) {
                        ForEach(allColors, id: \.self) { color in
                            Circle()
                                .fill(color.color)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(selectedColors.contains(color) ? Color.blue : Color.black, lineWidth: selectedColors.contains(color) ? 3 : 1)
                                )
                                .onTapGesture {
                                    toggleColorSelection(color)
                                }
                        }
                    }
                }

                // Size Filter
                Section(header: Text("Izmērs")) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))]) {
                        ForEach(0..<allSizes.count, id: \.self) { index in
                            Text(allSizes[index])
                                .frame(width: 50, height: 30)
                                .background(selectedSizes.contains(index) ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2))
                                .cornerRadius(8)
                                .onTapGesture {
                                    toggleSizeSelection(index)
                                }
                        }
                    }
                }

                // Seasons Filter (Dropdown)
                Section(header: Text("Sezona")) {
                    DisclosureGroup(isExpanded: $isSeasonDropdownExpanded) {
                        ForEach(allSeasons, id: \.self) { season in
                            Toggle(season.rawValue, isOn: Binding(
                                get: { selectedSeasons.contains(season) },
                                set: { isSelected in toggleSeasonSelection(season, isSelected: isSelected) }
                            ))
                        }
                    } label: {
                        Text("Izvēlieties sezonu")
                    }
                }

                // Last Worn Filter
                Section(header: Text("Pēdējoreiz vilkts")) {
                    DatePicker("Vilkts pirms", selection: Binding(
                        get: { selectedLastWorn ?? Date() },
                        set: { newValue in selectedLastWorn = newValue }
                    ), displayedComponents: .date)
                }

                // Laundering and Dirty Filters
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

                // Clear Filters Button
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

    private func toggleColorSelection(_ color: CustomColor) {
        if selectedColors.contains(color) {
            selectedColors.remove(color)
        } else {
            selectedColors.insert(color)
        }
    }

    private func toggleSizeSelection(_ size: Int) {
        if selectedSizes.contains(size) {
            selectedSizes.remove(size)
        } else {
            selectedSizes.insert(size)
        }
    }

    private func toggleSeasonSelection(_ season: Season, isSelected: Bool) {
        if isSelected {
            selectedSeasons.insert(season)
        } else {
            selectedSeasons.remove(season)
        }
    }

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
