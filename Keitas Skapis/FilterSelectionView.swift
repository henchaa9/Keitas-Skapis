//
//  FilterSelectionView.swift
//  Keitas Skapis
//
//  Created by Henrijs Obolevics on 30/12/2024.
//

import SwiftUI
import SwiftData

struct FilterSelectionView: View {
    // MARK: - Bindings for Filters
    
    @Binding var selectedColors: Set<CustomColor> // Tracks selected colors for filtering
    @Binding var selectedSizes: Set<Int> // Tracks selected sizes for filtering
    @Binding var selectedSeasons: Set<Season> // Tracks selected seasons for filtering
    @Binding var selectedLastWorn: Date? // Tracks the date for last worn filtering
    @Binding var isIronable: Bool? // Tracks if items are ironable (`gludinams`)
    @Binding var isWashing: Bool? // Tracks if items are washable (`mazgajas`)
    @Binding var isDirty: Bool? // Tracks if items are dirty (`netirs`)
    
    // MARK: - Available Options
    
    let allColors: [CustomColor] // List of all available colors based on unfiltered Apgerbs
    let allSizes = ["XS", "S", "M", "L", "XL"] // Predefined size options
    let allSeasons = Season.allCases // All possible seasons
    
    // MARK: - Environment
    
    @Environment(\.dismiss) var dismiss // Provides a method to dismiss the current view
    
    // MARK: - State Properties
    
    @State private var isSeasonDropdownExpanded = false // Controls the expansion of the seasons dropdown
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Colors Filter
                Section(header: Text("Krāsa")) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))]) {
                        ForEach(allColors, id: \.self) { color in
                            Circle()
                                .fill(color.color) // Displays the color
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(selectedColors.contains(color) ? Color.blue : Color.black, lineWidth: selectedColors.contains(color) ? 3 : 1) // Highlights selected colors
                                )
                                .onTapGesture {
                                    toggleColorSelection(color) // Toggles color selection
                                }
                        }
                    }
                }

                // MARK: - Size Filter
                Section(header: Text("Izmērs")) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))]) {
                        ForEach(0..<allSizes.count, id: \.self) { index in
                            Text(allSizes[index])
                                .frame(width: 50, height: 30)
                                .background(selectedSizes.contains(index) ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2)) // Highlights selected sizes
                                .cornerRadius(8)
                                .onTapGesture {
                                    toggleSizeSelection(index) // Toggles size selection
                                }
                        }
                    }
                }

                // MARK: - Seasons Filter (Dropdown)
                Section(header: Text("Sezona")) {
                    DisclosureGroup(isExpanded: $isSeasonDropdownExpanded) {
                        ForEach(allSeasons, id: \.self) { season in
                            Toggle(season.rawValue, isOn: Binding(
                                get: { selectedSeasons.contains(season) },
                                set: { isSelected in toggleSeasonSelection(season, isSelected: isSelected) }
                            )) // Toggles season selection
                        }
                    } label: {
                        Text("Izvēlieties sezonu") // Label for the dropdown
                    }
                }

                // MARK: - Last Worn Filter
                Section(header: Text("Pēdējoreiz vilkts")) {
                    DatePicker("Vilkts pirms", selection: Binding(
                        get: { selectedLastWorn ?? Date() },
                        set: { newValue in selectedLastWorn = newValue }
                    ), displayedComponents: .date) // Allows users to pick a date
                }

                // MARK: - Laundering and Dirty Filters
                Section(header: Text("Apģērba stāvoklis")) {
                    Toggle("Gludināms", isOn: Binding(
                        get: { isIronable ?? false },
                        set: { newValue in isIronable = newValue }
                    )) // Toggles ironable status
                    Toggle("Mazgājas", isOn: Binding(
                        get: { isWashing ?? false },
                        set: { newValue in isWashing = newValue }
                    )) // Toggles washable status
                    Toggle("Netīrs", isOn: Binding(
                        get: { isDirty ?? false },
                        set: { newValue in isDirty = newValue }
                    )) // Toggles dirty status
                }

                // MARK: - Clear Filters Button
                Section {
                    Button(action: clearFilters) {
                        Text("Notīrīt filtrus") // Button label to clear all filters
                            .foregroundColor(.red)
                    }
                    .frame(maxWidth: .infinity, alignment: .center) // Centers the button
                }
            }
            .navigationTitle("Filtri") // Sets the navigation title
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Aizvērt") {
                        dismiss() // Dismisses the filter view
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Pielietot") {
                        dismiss() // Applies the filters and dismisses the view
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods

    /// Toggles the selection state of a given color
    /// - Parameter color: The CustomColor to toggle
    private func toggleColorSelection(_ color: CustomColor) {
        if selectedColors.contains(color) {
            selectedColors.remove(color)
        } else {
            selectedColors.insert(color)
        }
    }

    /// Toggles the selection state of a given size
    /// - Parameter size: The index of the size to toggle
    private func toggleSizeSelection(_ size: Int) {
        if selectedSizes.contains(size) {
            selectedSizes.remove(size)
        } else {
            selectedSizes.insert(size)
        }
    }

    /// Toggles the selection state of a given season
    /// - Parameters:
    ///   - season: The Season to toggle
    ///   - isSelected: The new selection state
    private func toggleSeasonSelection(_ season: Season, isSelected: Bool) {
        if isSelected {
            selectedSeasons.insert(season)
        } else {
            selectedSeasons.remove(season)
        }
    }

    /// Clears all selected filters
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

