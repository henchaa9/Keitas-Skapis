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
    @Query private var clothingCategories: [ClothingCategory]
    @Query private var clothingItems: [ClothingItem]
    @Environment(\.modelContext) private var modelContext

    @State private var selectedCategories: Set<UUID> = [] // Tracks selected Kategorijas
    @State private var searchText: String = ""
    @State private var showFilterSheet = false
    @State private var showActionSheet = false
    @State private var actionSheetType: ActionSheetType?
    @State private var isEditing = false

    @State private var selectedCategory: ClothingCategory? // For long-press actions
    @State private var selectedClothingItem: ClothingItem? // For long-press actions

    @State private var selectedColors: Set<CustomColor> = []
    @State private var selectedSizes: Set<Int> = [] // Multiple sizes
    @State private var selectedSeasons: Set<Season> = []
    @State private var selectedLastWorn: Date? = nil
    @State private var isIronable: Bool? = nil
    @State private var isWashing: Bool? = nil
    @State private var isDirty: Bool? = nil
    @State private var allColors: [CustomColor] = [] // Caches colors from unfiltered Apgerbs
    
    @State private var isAddingCategory = false
    @State private var isAddingClothingItem = false
    @State private var selectedClothingItemsIDs: Set<UUID> = [] // Tracks selected Apgerbs
    @State private var showClothingItemDetail = false
    @State private var filteredClothingItems: [ClothingItem] = []
    @StateObject private var searchTextObservable = SearchTextObservable()
    @State private var isSelectionModeActive = false
    @State private var showHelpView = false // State to control the display of HelpView
    
    enum ActionSheetType {
        case clothingItemOptions, category, clothingItem, addOptions
    }
    
    var isFilterActive: Bool {
        !selectedColors.isEmpty ||
        !selectedSizes.isEmpty ||
        !selectedSeasons.isEmpty ||
        selectedLastWorn != nil ||
        isIronable != nil ||
        isWashing != nil ||
        isDirty != nil
    }


    var body: some View {
        NavigationStack {
            VStack {
                // Header
                HStack {
                    Text("Keitas Skapis").font(.title).bold().shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                    Spacer()
                    if !selectedClothingItemsIDs.isEmpty {
                        Button(action: {
                            actionSheetType = .clothingItemOptions
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
                            ForEach(clothingCategories, id: \.id) { category in
                                CategoryButton(
                                    clothingCategory: category,
                                    isSelected: selectedCategories.contains(category.id),
                                    onLongPress: { selected in
                                        selectedCategory = selected
                                        selectedClothingItem = nil // Reset other selection
                                        actionSheetType = .category
                                        showActionSheet = true
                                    },
                                    toggleSelection: toggleCategorySelection
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
                                        selectedClothingItemsIDs.removeAll()
                                    }
                                }

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90, maximum: 120))], spacing: 10) {
                                ForEach(filteredClothingItems, id: \.id) { item in
                                    ApgerbsButton(
                                        clothingItem: item,
                                        isSelected: selectedClothingItemsIDs.contains(item.id),
                                        onTap: {
                                            if isSelectionModeActive {
                                                toggleClothingItemSelection(item)
                                            } else {
                                                // Show detail when not in selection mode
                                                selectedClothingItem = item
                                                showClothingItemDetail = true
                                            }
                                        },
                                        onLongPress: {
                                            if !isSelectionModeActive {
                                                isSelectionModeActive = true
                                            }
                                            toggleClothingItemSelection(item)
                                        }
                                    )
                                }
                            }
                            .padding()
                        }
                    }
                    .sheet(isPresented: $showClothingItemDetail) {
                        if let item = selectedClothingItem {
                            ApgerbsDetailView(
                                clothingItem: item,
                                onEdit: {
                                    isEditing = true
                                    showClothingItemDetail = false
                                },
                                onDelete: {
                                    deleteSelectedClothingItem()
                                    showClothingItemDetail = false
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
                    getActionSheet()
                }
                .sheet(isPresented: $showFilterSheet) {
                    FilterSelectionView(
                        selectedColors: $selectedColors,
                        selectedSizes: $selectedSizes,
                        selectedSeasons: $selectedSeasons,
                        selectedLastWorn: $selectedLastWorn,
                        isIronable: $isIronable,
                        isWashing: $isWashing,
                        isDirty: $isDirty,
                        allColors: allColors
                    )
                }
                .navigationDestination(isPresented: $isAddingCategory) {
                    PievienotKategorijuView()
                }
                .navigationDestination(isPresented: $isAddingClothingItem) {
                    PievienotApgerbuView()
                }
                .navigationDestination(isPresented: $isEditing) {
                    if let category = selectedCategory {
                        PievienotKategorijuView(existingCategory: category)
                            .onDisappear {
                                isEditing = false
                                selectedCategory = nil
                            }
                    } else if let item = selectedClothingItem {
                        PievienotApgerbuView(existingClothingItem: item)
                            .onDisappear {
                                isEditing = false
                                selectedClothingItem = nil
                            }
                    }
                }
                .onChange(of: searchTextObservable.debouncedSearchText) { oldValue, newValue in
                    performFiltering()
                }
                .onChange(of: selectedCategories) { oldValue, newValue in
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
                .onChange(of: isWashing) { oldValue, newValue in
                    performFiltering()
                }
                .onChange(of: isDirty) { oldValue, newValue in
                    performFiltering()
                }
                .onAppear {
                    allColors = Array(Set(clothingItems.map { $0.color }))
                    performFiltering()
                }
                .preferredColorScheme(.light)
            }
        }
    
    
    private func getActionSheet() -> ActionSheet {
        switch actionSheetType {
        case .category:
            return categoryActionSheet()
        case .clothingItem:
            return clothingItemActionSheet()
        case .addOptions:
            return addOptionsActionSheet()
        case .clothingItemOptions:
            return clothingItemActionSheet()
        case .none:
            return ActionSheet(title: Text("No Action"))
        }
    }


    func performFiltering() {
        DispatchQueue.global(qos: .userInitiated).async {
            let result = clothingItems.filter { item in
                // Your existing filtering conditions
                (selectedCategories.isEmpty || item.clothingItemCategories.contains { selectedCategories.contains($0.id) }) &&
                (selectedColors.isEmpty || selectedColors.contains(item.color)) &&
                (selectedSizes.isEmpty || selectedSizes.contains(item.size)) &&
                (selectedSeasons.isEmpty || !Set(item.season).intersection(selectedSeasons).isEmpty) &&
                (selectedLastWorn == nil || item.lastWorn <= selectedLastWorn!) &&
                (isIronable == nil || item.ironable == isIronable) &&
                (isWashing == nil || item.washing == isWashing) &&
                (isDirty == nil || item.dirty == isDirty) &&
                (searchTextObservable.debouncedSearchText.isEmpty || item.name.localizedCaseInsensitiveContains(searchTextObservable.debouncedSearchText))
            }
            DispatchQueue.main.async {
                self.filteredClothingItems = result
            }
        }
    }

        
    private func addOptionsActionSheet() -> ActionSheet {
        ActionSheet(
            title: Text("Pievienot"),
            buttons: [
                .default(Text("Pievienot apģērbu")) {
                    isAddingClothingItem = true
                },
                .default(Text("Pievienot kategoriju")) {
                    isAddingCategory = true
                },
                .cancel(Text("Atcelt"))
            ]
        )
    }


    private func categoryActionSheet() -> ActionSheet {
        ActionSheet(
            title: Text("Pārvaldīt \(selectedCategory?.name ?? "")"),
            message: Text("Šī kategorija satur \(selectedCategory?.categoryClothingItems.count ?? 0) apģērbu(s)."),
            buttons: [
                .default(Text("Rediģēt")) {
                    isEditing = true
                },
                .default(Text("Dzēst tikai kategoriju")) {
                    removeCategoryOnly()
                },
                .destructive(Text("Dzēst kategoriju un apģērbus")) {
                    deleteCategoryAndItems()
                },
                .cancel()
            ]
        )
    }

    private func clothingItemActionSheet() -> ActionSheet {
        ActionSheet(
            title: Text("Pārvaldīt apģērbus"),
            buttons: [
                .default(Text("Mainīt uz Tīrs")) {
                    updateClothingItemStatus(to: "tirs")
                },
                .default(Text("Mainīt uz Netīrs")) {
                    updateClothingItemStatus(to: "netirs")
                },
                .default(Text("Mainīt uz Mazgājas")) {
                    updateClothingItemStatus(to: "mazgajas")
                },
                .destructive(Text("Dzēst")) {
                    deleteSelectedClothingItem()
                },
                .cancel()
            ]
        )
    }

    private func toggleClothingItemSelection(_ clothingItem: ClothingItem) {
        if selectedClothingItemsIDs.contains(clothingItem.id) {
            selectedClothingItemsIDs.remove(clothingItem.id)
        } else {
            selectedClothingItemsIDs.insert(clothingItem.id)
        }

        // Exit selection mode if no items remain selected
        if selectedClothingItemsIDs.isEmpty {
            isSelectionModeActive = false
        }
    }


    private func updateClothingItemStatus(to status: String) {
        for item in clothingItems where selectedClothingItemsIDs.contains(item.id) {
            switch status {
            case "tirs":
                item.dirty = false
                item.washing = false
            case "netirs":
                item.dirty = true
                item.washing = false
            case "mazgajas":
                item.dirty = false
                item.washing = true
            default:
                break
            }
        }
        selectedClothingItemsIDs.removeAll()
        isSelectionModeActive = false // Exit multi-selection mode
        try? modelContext.save()
    }


    private func removeCategoryOnly() {
        if let category = selectedCategory {
            for item in category.categoryClothingItems {
                item.clothingItemCategories.removeAll { $0 == category }
            }
            modelContext.delete(category)
            selectedCategory = nil
        }
    }

    private func deleteCategoryAndItems() {
        if let category = selectedCategory {
            for item in category.categoryClothingItems {
                modelContext.delete(item)
            }
            modelContext.delete(category)
            selectedCategory = nil
        }
    }

    private func deleteSelectedClothingItem() {
        // 1) If we came from the detail view (one item)
        if let single = selectedClothingItem {
            // Clear single selection + dismiss
            selectedClothingItem = nil
            showClothingItemDetail = false

            // Delete just that one
            DispatchQueue.main.async {
                modelContext.delete(single)
                try? modelContext.save()
                performFiltering()
            }
        }
        // 2) Otherwise, if we have multi-selections:
        else if !selectedClothingItemsIDs.isEmpty {
            DispatchQueue.main.async {
                // Loop all Apgerbs in query, delete if in selected set
                for item in clothingItems where selectedClothingItemsIDs.contains(item.id) {
                    modelContext.delete(item)
                }
                selectedClothingItemsIDs.removeAll()
                isSelectionModeActive = false // Exit multi-selection mode
                try? modelContext.save()
                performFiltering()
            }
        }
    }


    // Toggle Kategorija Selection
    private func toggleCategorySelection(_ kategorija: ClothingCategory) {
        if selectedCategories.contains(kategorija.id) {
            selectedCategories.remove(kategorija.id)
        } else {
            selectedCategories.insert(kategorija.id)
        }
    }
}

class ImageLoader: ObservableObject {
    @Published var image: UIImage?

    private let clothingItem: ClothingItem

    init(clothingItem: ClothingItem) {
        self.clothingItem = clothingItem
        self.loadImage()
    }

    func loadImage() {
        clothingItem.loadImage { [weak self] loadedImage in
            self?.image = loadedImage
        }
    }
}


struct AsyncImageView: View {
    @ObservedObject private var loader: ImageLoader

    init(clothingItem: ClothingItem) {
        self.loader = ImageLoader(clothingItem: clothingItem)
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
