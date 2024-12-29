//
//  ContentView.swift
//  Keitas Skapis
//
//  Created by Henrijs Obolevics on 31/08/2024.
//

import SwiftUI
import SwiftData
import Combine

class SearchTextObservable: ObservableObject {
    @Published var searchText: String = ""
    @Published var debouncedSearchText: String = ""

    private var cancellables = Set<AnyCancellable>()

    init() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] in
                self?.debouncedSearchText = $0
            }
            .store(in: &cancellables)
    }
}


struct ContentView: View {
    @Query private var kategorijas: [Kategorija]
    @Query private var apgerbi: [Apgerbs]
    @Environment(\.modelContext) private var modelContext

    @State private var selectedKategorijas: Set<UUID> = [] // Tracks selected Kategorijas
    @State private var searchText: String = ""
    @State private var showFilterSheet = false
    @State private var showActionSheet = false
    @State private var actionSheetType: ActionSheetType?
    @State private var isEditing = false

    @State private var selectedKategorija: Kategorija? // For long-press actions
    @State private var selectedApgerbs: Apgerbs? // For long-press actions

    @State private var selectedColors: Set<Krasa> = []
    @State private var selectedSizes: Set<Int> = [] // Multiple sizes
    @State private var selectedSeasons: Set<Sezona> = []
    @State private var selectedLastWorn: Date? = nil
    @State private var isIronable: Bool? = nil
    @State private var isLaundering: Bool? = nil
    @State private var isDirty: Bool? = nil
    @State private var allColors: [Krasa] = [] // Caches colors from unfiltered Apgerbs
    
    @State private var isAddingKategorija = false
    @State private var isAddingApgerbs = false
    @State private var selectedApgerbsIDs: Set<UUID> = [] // Tracks selected Apgerbs
    @State private var showApgerbsDetail = false
    @State private var filteredApgerbi: [Apgerbs] = []
    @StateObject private var searchTextObservable = SearchTextObservable()
    @State private var isSelectionModeActive = false
    @State private var showHelpView = false // State to control the display of HelpView
    
    enum ActionSheetType {
        case apgerbsOptions, kategorija, apgerbs, addOptions
    }
    
    var isFilterActive: Bool {
        !selectedColors.isEmpty ||
        !selectedSizes.isEmpty ||
        !selectedSeasons.isEmpty ||
        selectedLastWorn != nil ||
        isIronable != nil ||
        isLaundering != nil ||
        isDirty != nil
    }


    var body: some View {
        NavigationStack {
            VStack {
                // Header
                HStack {
                    Text("Keitas Skapis").font(.title).bold().shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                    Spacer()
                    if !selectedApgerbsIDs.isEmpty {
                        Button(action: {
                            actionSheetType = .apgerbsOptions
                            showActionSheet = true
                        }) {
                            Image(systemName: "pencil")
                                .resizable()
                                .frame(width: 20, height: 20)
                                .bold()
                                .foregroundStyle(.black)
                                .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                        }
                    }
                    
                    Button(action: {
                        actionSheetType = .addOptions
                        showActionSheet = true
                    }) {
                        Image(systemName: "plus")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .bold()
                            .foregroundStyle(.black)
                            .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                            .padding(.horizontal, 5)
                    }
                    
                    Button(action: {
                        showHelpView = true
                    }) {
                        Image(systemName: "questionmark")
                            .resizable()
                            .frame(width: 14, height: 20)
                            .bold()
                            .foregroundStyle(.black)
                            .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                    }
                    .sheet(isPresented: $showHelpView) {
                        HelpView()
                    }
                    
                }.padding().background(Color(.systemGray6)).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.black), lineWidth: 1)).padding(.horizontal, 10).shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)

                
                HStack {
                    Text("Kategorijas").padding(.vertical, 5)
                        .padding(.horizontal, 10)
                        .bold()
                        .background(Color(.white))
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.black), lineWidth: 1))
                        .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                    Spacer()
                }.padding(.leading, 15)
                
                    // Categories Section
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(kategorijas, id: \.id) { kategorija in
                                CategoryButton(
                                    kategorija: kategorija,
                                    isSelected: selectedKategorijas.contains(kategorija.id),
                                    onLongPress: { selected in
                                        selectedKategorija = selected
                                        selectedApgerbs = nil // Reset other selection
                                        actionSheetType = .kategorija
                                        showActionSheet = true
                                    },
                                    toggleSelection: toggleKategorijaSelection
                                )
                            }
                        }.padding(5)
                    }
                    .padding(.horizontal, 10)
                
                HStack {
                    Text("Apģērbi").padding(.vertical, 5)
                        .padding(.horizontal, 10)
                        .bold()
                        .background(Color(.white))
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.black), lineWidth: 1))
                        .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                    Spacer()
                }.padding(.leading, 15)
                    
                    // Search Bar with Filter Button
                    HStack {
                        TextField("Meklēt", text: $searchTextObservable.searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
//                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.black), lineWidth: 1))
                            .padding(.horizontal)
                            .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                        
                        Button(action: {
                            showFilterSheet = true
                        }) {
                            ZStack {
                                if isFilterActive {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.blue.opacity(0.2))
                                        .frame(width: 35, height: 35) // Ensure the background size is consistent
                                }
                                Image(systemName: "slider.horizontal.3")
                                    .resizable()
                                    .frame(width: 25, height: 20)
                                    .foregroundColor(isFilterActive ? .blue : .black)
                                    .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                            }
                        }.padding(.trailing)

                    }
                    
                    // Clothing Items Section
                    ScrollView {
                        ZStack {
                            // Background to detect taps on empty space
                            Color.clear
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if isSelectionModeActive {
                                        isSelectionModeActive = false
                                        selectedApgerbsIDs.removeAll()
                                    }
                                }

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90, maximum: 120))], spacing: 10) {
                                ForEach(filteredApgerbi, id: \.id) { apgerbs in
                                    ApgerbsButton(
                                        apgerbs: apgerbs,
                                        isSelected: selectedApgerbsIDs.contains(apgerbs.id),
                                        onTap: {
                                            if isSelectionModeActive {
                                                toggleApgerbsSelection(apgerbs)
                                            } else {
                                                // Show detail when not in selection mode
                                                selectedApgerbs = apgerbs
                                                showApgerbsDetail = true
                                            }
                                        },
                                        onLongPress: {
                                            if !isSelectionModeActive {
                                                isSelectionModeActive = true
                                            }
                                            toggleApgerbsSelection(apgerbs)
                                        }
                                    )
                                }
                            }
                            .padding()
                        }
                    }
                    .sheet(isPresented: $showApgerbsDetail) {
                        if let apgerbs = selectedApgerbs {
                            ApgerbsDetailView(
                                apgerbs: apgerbs,
                                onEdit: {
                                    isEditing = true
                                    showApgerbsDetail = false
                                },
                                onDelete: {
                                    deleteSelectedApgerbs()
                                    showApgerbsDetail = false
                                }
                            )
                        } else {
                            Text("No Apgerbs Selected")
                        }
                    }
            }.background(Image("background_dmitriy_steinke").resizable().edgesIgnoringSafeArea(.all).opacity(0.3)).hideKeyboardOnTap()
                ToolBar()
                .background(Color(.systemGray5)).padding(.top, -10)
                .navigationBarBackButtonHidden(true)
                .actionSheet(isPresented: $showActionSheet) {
                    switch actionSheetType {
                    case .kategorija:
                        return kategorijaActionSheet()
                    case .apgerbs:
                        return apgerbsActionSheet()
                    case .addOptions:
                        return addOptionsActionSheet()
                    case .apgerbsOptions:
                        return apgerbsActionSheet()
                    case .none:
                        return ActionSheet(title: Text("No Action"))
                    }
                }
                .sheet(isPresented: $showFilterSheet) {
                    FilterSelectionView(
                        selectedColors: $selectedColors,
                        selectedSizes: $selectedSizes,
                        selectedSeasons: $selectedSeasons,
                        selectedLastWorn: $selectedLastWorn,
                        isIronable: $isIronable,
                        isLaundering: $isLaundering,
                        isDirty: $isDirty,
                        allColors: allColors // Pass cached colors
                    )
                }
                .navigationDestination(isPresented: $isAddingKategorija) {
                    PievienotKategorijuView()
                }
                .navigationDestination(isPresented: $isAddingApgerbs) {
                    PievienotApgerbuView()
                }
                .navigationDestination(isPresented: $isEditing) {
                    if let kategorija = selectedKategorija {
                        PievienotKategorijuView(existingKategorija: kategorija)
                            .onDisappear {
                                isEditing = false
                                selectedKategorija = nil
                            }
                    } else if let apgerbs = selectedApgerbs {
                        PievienotApgerbuView(existingApgerbs: apgerbs)
                            .onDisappear {
                                isEditing = false
                                selectedApgerbs = nil
                            }
                    }
                }
                .onChange(of: searchTextObservable.debouncedSearchText) { oldValue, newValue in
                    performFiltering()
                }
                .onChange(of: selectedKategorijas) { oldValue, newValue in
                    performFiltering()
                }
                .onChange(of: selectedColors) { oldValue, newValue in
                    performFiltering()
                }
                .onChange(of: selectedSizes) { oldValue, newValue in
                    performFiltering()
                }
                .onChange(of: selectedSeasons) { oldValue, newValue in
                    performFiltering()
                }
                .onChange(of: selectedLastWorn) { oldValue, newValue in
                    performFiltering()
                }
                .onChange(of: isIronable) { oldValue, newValue in
                    performFiltering()
                }
                .onChange(of: isLaundering) { oldValue, newValue in
                    performFiltering()
                }
                .onChange(of: isDirty) { oldValue, newValue in
                    performFiltering()
                }
                .onAppear {
                    allColors = Array(Set(apgerbi.map { $0.krasa }))
                    // Apply any active filters
                    performFiltering()
                }
                .preferredColorScheme(.light)
            }
        }

    func performFiltering() {
        DispatchQueue.global(qos: .userInitiated).async {
            let result = apgerbi.filter { apgerbs in
                // Your existing filtering conditions
                (selectedKategorijas.isEmpty || apgerbs.kategorijas.contains { selectedKategorijas.contains($0.id) }) &&
                (selectedColors.isEmpty || selectedColors.contains(apgerbs.krasa)) &&
                (selectedSizes.isEmpty || selectedSizes.contains(apgerbs.izmers)) &&
                (selectedSeasons.isEmpty || !Set(apgerbs.sezona).intersection(selectedSeasons).isEmpty) &&
                (selectedLastWorn == nil || apgerbs.pedejoreizVilkts <= selectedLastWorn!) &&
                (isIronable == nil || apgerbs.gludinams == isIronable) &&
                (isLaundering == nil || apgerbs.mazgajas == isLaundering) &&
                (isDirty == nil || apgerbs.netirs == isDirty) &&
                (searchTextObservable.debouncedSearchText.isEmpty || apgerbs.nosaukums.localizedCaseInsensitiveContains(searchTextObservable.debouncedSearchText))
            }
            DispatchQueue.main.async {
                self.filteredApgerbi = result
            }
        }
    }

        
    private func addOptionsActionSheet() -> ActionSheet {
        ActionSheet(
            title: Text("Pievienot"),
            buttons: [
                .default(Text("Pievienot apģērbu")) {
                    isAddingApgerbs = true
                },
                .default(Text("Pievienot kategoriju")) {
                    isAddingKategorija = true
                },
                .cancel(Text("Atcelt"))
            ]
        )
    }


    private func kategorijaActionSheet() -> ActionSheet {
        ActionSheet(
            title: Text("Pārvaldīt \(selectedKategorija?.nosaukums ?? "")"),
            message: Text("Šī kategorija satur \(selectedKategorija?.apgerbi.count ?? 0) apģērbu(s)."),
            buttons: [
                .default(Text("Rediģēt")) {
                    isEditing = true
                },
                .default(Text("Dzēst tikai kategoriju")) {
                    removeKategorijaOnly()
                },
                .destructive(Text("Dzēst kategoriju un apģērbus")) {
                    deleteKategorijaAndItems()
                },
                .cancel()
            ]
        )
    }

    private func apgerbsActionSheet() -> ActionSheet {
        ActionSheet(
            title: Text("Pārvaldīt apģērbus"),
            buttons: [
                .default(Text("Mainīt uz Tīrs")) {
                    updateApgerbsStatus(to: "tirs")
                },
                .default(Text("Mainīt uz Netīrs")) {
                    updateApgerbsStatus(to: "netirs")
                },
                .default(Text("Mainīt uz Mazgājas")) {
                    updateApgerbsStatus(to: "mazgajas")
                },
                .destructive(Text("Dzēst")) {
                    deleteSelectedApgerbs()
                },
                .cancel()
            ]
        )
    }

    private func toggleApgerbsSelection(_ apgerbs: Apgerbs) {
        if selectedApgerbsIDs.contains(apgerbs.id) {
            selectedApgerbsIDs.remove(apgerbs.id)
        } else {
            selectedApgerbsIDs.insert(apgerbs.id)
        }

        // Exit selection mode if no items remain selected
        if selectedApgerbsIDs.isEmpty {
            isSelectionModeActive = false
        }
    }


    private func updateApgerbsStatus(to status: String) {
        for apgerbs in apgerbi where selectedApgerbsIDs.contains(apgerbs.id) {
            switch status {
            case "tirs":
                apgerbs.netirs = false
                apgerbs.mazgajas = false
            case "netirs":
                apgerbs.netirs = true
                apgerbs.mazgajas = false
            case "mazgajas":
                apgerbs.netirs = false
                apgerbs.mazgajas = true
            default:
                break
            }
        }
        selectedApgerbsIDs.removeAll()
        try? modelContext.save()   
    }


    private func removeKategorijaOnly() {
        if let kategorija = selectedKategorija {
            for apgerbs in kategorija.apgerbi {
                apgerbs.kategorijas.removeAll { $0 == kategorija }
            }
            modelContext.delete(kategorija)
            selectedKategorija = nil
        }
    }

    private func deleteKategorijaAndItems() {
        if let kategorija = selectedKategorija {
            for apgerbs in kategorija.apgerbi {
                modelContext.delete(apgerbs)
            }
            modelContext.delete(kategorija)
            selectedKategorija = nil
        }
    }

    private func deleteSelectedApgerbs() {
        // 1) If we came from the detail view (one item)
        if let single = selectedApgerbs {
            // Clear single selection + dismiss
            selectedApgerbs = nil
            showApgerbsDetail = false

            // Delete just that one
            DispatchQueue.main.async {
                modelContext.delete(single)
                try? modelContext.save()
                performFiltering()
            }
        }
        // 2) Otherwise, if we have multi-selections:
        else if !selectedApgerbsIDs.isEmpty {
            DispatchQueue.main.async {
                // Loop all Apgerbs in query, delete if in selected set
                for apgerbs in apgerbi where selectedApgerbsIDs.contains(apgerbs.id) {
                    modelContext.delete(apgerbs)
                }
                selectedApgerbsIDs.removeAll()
                try? modelContext.save()
                performFiltering()
            }
        }
    }


    // Toggle Kategorija Selection
    private func toggleKategorijaSelection(_ kategorija: Kategorija) {
        if selectedKategorijas.contains(kategorija.id) {
            selectedKategorijas.remove(kategorija.id)
        } else {
            selectedKategorijas.insert(kategorija.id)
        }
    }
}

class ImageLoader: ObservableObject {
    @Published var image: UIImage?

    private let apgerbs: Apgerbs

    init(apgerbs: Apgerbs) {
        self.apgerbs = apgerbs
        self.loadImage()
    }

    func loadImage() {
        apgerbs.loadImage { [weak self] loadedImage in
            self?.image = loadedImage
        }
    }
}


struct AsyncImageView: View {
    @ObservedObject private var loader: ImageLoader

    init(apgerbs: Apgerbs) {
        self.loader = ImageLoader(apgerbs: apgerbs)
    }

    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                // Placeholder or ProgressView
                ProgressView()
            }
        }
    }
}




struct FilterSelectionView: View {
    @Binding var selectedColors: Set<Krasa> // For color filtering
    @Binding var selectedSizes: Set<Int> // For size filtering
    @Binding var selectedSeasons: Set<Sezona> // For season filtering
    @Binding var selectedLastWorn: Date? // For last worn filtering
    @Binding var isIronable: Bool? // For `gludinams`
    @Binding var isLaundering: Bool? // For `mazgajas`
    @Binding var isDirty: Bool? // For `netirs`

    let allColors: [Krasa] // Static list of colors based on unfiltered Apgerbs
    let allSizes = ["XS", "S", "M", "L", "XL"]
    let allSeasons = Sezona.allCases

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
                        get: { isLaundering ?? false },
                        set: { newValue in isLaundering = newValue }
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

    private func toggleColorSelection(_ color: Krasa) {
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

    private func toggleSeasonSelection(_ season: Sezona, isSelected: Bool) {
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
        isLaundering = nil
        isDirty = nil
    }
}

    
#Preview {
    ContentView()
}
