//
//  ContentViewModel.swift
//  Keitas Skapis
//
//  Created by Henrijs Obolevics on 08/12/2024.
//

import SwiftUI
import Combine

class ContentViewModel: ObservableObject {
    // Inputs
    @Published var allApgerbi: [Apgerbs] = []
    @Published var selectedKategorijas: Set<UUID> = []
    @Published var selectedColors: Set<Krasa> = []
    @Published var selectedSizes: Set<Int> = []
    @Published var selectedSeasons: Set<Sezona> = []
    @Published var selectedLastWorn: Date? = nil
    @Published var isIronable: Bool? = nil
    @Published var isLaundering: Bool? = nil
    @Published var isDirty: Bool? = nil
    @Published var debouncedSearchText: String = ""

    // Outputs
    @Published var filteredApgerbi: [Apgerbs] = []
    @Published var allColors: [Krasa] = []

    private var cancellables = Set<AnyCancellable>()

    init() {
        let kategorijasPub = $selectedKategorijas.eraseToAnyPublisher()
        let colorsPub = $selectedColors.eraseToAnyPublisher()
        let sizesPub = $selectedSizes.eraseToAnyPublisher()
        let seasonsPub = $selectedSeasons.eraseToAnyPublisher()
        let wornPub = $selectedLastWorn.eraseToAnyPublisher()
        let ironablePub = $isIronable.eraseToAnyPublisher()
        let launderingPub = $isLaundering.eraseToAnyPublisher()
        let dirtyPub = $isDirty.eraseToAnyPublisher()
        let searchPub = $debouncedSearchText.eraseToAnyPublisher()

        // Combine two at a time:
        let combined1 = kategorijasPub.combineLatest(colorsPub)
        // (Set<UUID>, Set<Krasa>)

        let combined2 = combined1.combineLatest(sizesPub)
        // ((Set<UUID>, Set<Krasa>), Set<Int>)

        let combined3 = combined2.combineLatest(seasonsPub)
        // (((Set<UUID>, Set<Krasa>), Set<Int>), Set<Sezona>)

        let combined4 = combined3.combineLatest(wornPub)
        // ((((Set<UUID>, Set<Krasa>), Set<Int>), Set<Sezona>), Date?)

        let combined5 = combined4.combineLatest(ironablePub)
        // (((((Set<UUID>, Set<Krasa>), Set<Int>), Set<Sezona>), Date?), Bool?)

        let combined6 = combined5.combineLatest(launderingPub)
        // ((((((Set<UUID>, Set<Krasa>), Set<Int>), Set<Sezona>), Date?), Bool?), Bool?)

        let combined7 = combined6.combineLatest(dirtyPub)
        // (((((((Set<UUID>, Set<Krasa>), Set<Int>), Set<Sezona>), Date?), Bool?), Bool?), Bool?)

        let combinedAll = combined7.combineLatest(searchPub)
        // ((((((((Set<UUID>, Set<Krasa>), Set<Int>), Set<Sezona>), Date?), Bool?), Bool?), Bool?), String)

        // Now we have a very nested tuple. Let's map it to a simpler structure:
        let simplified = combinedAll
            .map { value -> Void in
                // We don't actually need to extract each value here for the filtering,
                // because we call applyFilters() which reads from the @Published properties.
                // If we needed to, we could break it down, but since applyFilters() uses the published properties,
                // we only need to trigger it.
                return ()
            }
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()

        simplified
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
    }


    func setInitialData(_ apgerbi: [Apgerbs]) {
        self.allApgerbi = apgerbi
        self.allColors = Array(Set(apgerbi.map { $0.krasa }))
        applyFilters()
    }

    private func applyFilters() {
        
        print("Filtering...")
        
        // Capture values outside the closure to simplify the filter conditions
        let apgerbi = self.allApgerbi
        let selectedCats = self.selectedKategorijas
        let selectedCols = self.selectedColors
        let selectedSiz = self.selectedSizes
        let selectedSeas = self.selectedSeasons
        let lastWorn = self.selectedLastWorn
        let iron = self.isIronable
        let laundry = self.isLaundering
        let dirty = self.isDirty
        let search = self.debouncedSearchText

        DispatchQueue.global(qos: .userInitiated).async {
            let result = apgerbi.filter { apgerbs in
                let matchesKats = selectedCats.isEmpty || apgerbs.kategorijas.contains { selectedCats.contains($0.id) }
                let matchesColors = selectedCols.isEmpty || selectedCols.contains(apgerbs.krasa)
                let matchesSizes = selectedSiz.isEmpty || selectedSiz.contains(apgerbs.izmers)
                let matchesSeasons = selectedSeas.isEmpty || !Set(apgerbs.sezona).intersection(selectedSeas).isEmpty
                let matchesLastWorn = (lastWorn == nil) || (apgerbs.pedejoreizVilkts <= lastWorn!)
                let matchesIron = (iron == nil) || (apgerbs.gludinams == iron)
                let matchesLaundering = (laundry == nil) || (apgerbs.mazgajas == laundry)
                let matchesDirty = (dirty == nil) || (apgerbs.netirs == dirty)
                let matchesSearch = search.isEmpty || apgerbs.nosaukums.localizedCaseInsensitiveContains(search)

                return matchesKats && matchesColors && matchesSizes && matchesSeasons && matchesLastWorn && matchesIron && matchesLaundering && matchesDirty && matchesSearch
            }

            DispatchQueue.main.async {
                self.filteredApgerbi = result
            }
        }
    }
}

