
import SwiftUI
import SwiftData
import Combine

// MARK: - SearchTextObservable

// Objekts, kas palīdz pārvaldīt apģērbu meklēšanu
class SearchTextObservable: ObservableObject {
    // Mainīgie meklētā teksta uzglabāšanai
    @Published var searchText: String = ""
    @Published var debouncedSearchText: String = ""

    // Uzglabā notiekošos procesus, lai tos būtu iespējams atcelt
    private var cancellables = Set<AnyCancellable>()

    // Inicializē SearchTextObservable un sagatavo teksta 'debouncing' jeb rezultātu aizkavi
    init() {
        // Aizkavē meklēšanas rezultātu apstrādi
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] in
                self?.debouncedSearchText = $0
            }
            .store(in: &cancellables)
    }
}

// MARK: - ContentView

// Galvenais skats (Sākums)
struct HomeView: View {
    // MARK: - Datu vaicājumi un vides mainīgie
    @Query private var clothingCategories: [ClothingCategory]
    @Query private var clothingItems: [ClothingItem]
    @Environment(\.modelContext) private var modelContext

    // MARK: - Stāvokļu mainīgie
    @State private var selectedCategories: Set<UUID> = []
    @State private var searchText: String = ""
    @State private var showFilterSheet = false
    @State private var showActionSheet = false
    @State private var actionSheetType: ActionSheetType?
    @State private var isEditing = false

    @State private var selectedCategory: ClothingCategory?
    @State private var selectedClothingItem: ClothingItem? 

    @State private var selectedColors: Set<CustomColor> = []
    @State private var selectedSizes: Set<Int> = []
    @State private var selectedSeasons: Set<Season> = []
    @State private var selectedLastWorn: Date? = nil
    @State private var isIronable: Bool? = nil
    @State private var isWashing: Bool? = nil
    @State private var isDirty: Bool? = nil
    @State private var allColors: [CustomColor] = []

    @State private var isAddingCategory = false
    @State private var isAddingClothingItem = false
    @State private var selectedClothingItemsIDs: Set<UUID> = []
    @State private var showClothingItemDetail = false
    @State private var filteredClothingItems: [ClothingItem] = []
    @StateObject private var searchTextObservable = SearchTextObservable()
    @State private var isSelectionModeActive = false
    @State private var showHelpView = false

    // MARK: - Kļūdu apstrādes mainīgie
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""

    // MARK: - ActionSheet veidi
    enum ActionSheetType {
        case clothingItemOptions, category, clothingItem, addOptions
    }

    // Mainīgais, kas glabā informāciju par aktīvajiem filtriem
    var isFilterActive: Bool {
        !selectedColors.isEmpty ||
        !selectedSizes.isEmpty ||
        !selectedSeasons.isEmpty ||
        selectedLastWorn != nil ||
        isIronable != nil ||
        isWashing != nil ||
        isDirty != nil
    }


    // MARK: - Galvenais saturs
    var body: some View {
        NavigationStack {
            VStack {
                // Galvenes sadaļa
                headerView

                // Kategoriju sadaļa
                categoriesSection

                // Apģērbu sadaļa
                clothingItemsSection
            }
            .background(
                Image("background_dmitriy_steinke")
                    .resizable()
                    .edgesIgnoringSafeArea(.all)
                    .opacity(0.3)
            )
            .hideKeyboardOnTap()
                ToolBar()
                .background(Color(.systemGray5))
                .padding(.top, -10)
            .background(Color(.systemGray6))
            .navigationBarBackButtonHidden(true)
            // Lapu parādīšana
            .actionSheet(isPresented: $showActionSheet) {
                getActionSheet()
            }
            .sheet(isPresented: $showFilterSheet) {
                // Filtru lapa
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
            .sheet(isPresented: $showClothingItemDetail) {
                // Apģērba detaļu lapa
                if let item = selectedClothingItem {
                    clothingItemDetailView(
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
            .navigationDestination(isPresented: $isAddingCategory) {
                // Jaunas kategorijas pievienošanas skats
                addClothingCategoryView()
            }
            .navigationDestination(isPresented: $isAddingClothingItem) {
                // Jauna apģērba pievienošanas skats
                PievienotApgerbuView()
            }
            .navigationDestination(isPresented: $isEditing) {
                // Rediģēšanas skati kategorijām vai apģērbiem
                if let category = selectedCategory {
                    addClothingCategoryView(existingCategory: category)
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
            // 'Vērotāji' izmaiņām filtros un meklēšanas tekstā
            .onChange(of: searchTextObservable.debouncedSearchText) { _, _ in
                performFiltering()
            }
            .onChange(of: selectedCategories) { _, _ in
                performFiltering()
            }
            .onChange(of: selectedColors) { _, _ in
                performFiltering()
            }
            .onChange(of: selectedSizes) { _, _ in
                performFiltering()
            }
            .onChange(of: selectedSeasons) { _, _ in
                performFiltering()
            }
            .onChange(of: selectedLastWorn) { _, _ in
                performFiltering()
            }
            .onChange(of: isIronable) { _, _ in
                performFiltering()
            }
            .onChange(of: isWashing) { _, _ in
                performFiltering()
            }
            .onChange(of: isDirty) { _, _ in
                performFiltering()
            }
            .onAppear {
                // Inicializē krāsas un veic sākotnējo filtrēšanu
                allColors = Array(Set(clothingItems.map { $0.color }))
                performFiltering()
            }
            .preferredColorScheme(.light)
            // Kļūdas paziņojums lietotājam
            .alert(isPresented: $showErrorAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    // MARK: - Galvenes sadaļa

    private var headerView: some View {
        HStack {
            Text("Keitas Skapis")
                .font(.title)
                .bold()
                .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
            Spacer()
            // Rediģēšanas poga, kas redzama, ja tiek izvēlēts kāds apģērbs
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

            // Kategoriju / Apģērbu pievienošanas poga
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

            // Poga, kas atver palīdzības / lietošanas instrukcijas skatu
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

        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.black), lineWidth: 1)
        )
        .padding(.horizontal, 10)
        .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
    }

    // MARK: - Kategoriju sadaļa

    // Horizontāli attēlotas kategorijas
    private var categoriesSection: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Kategorijas")
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .bold()
                    .background(Color(.white))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(.black), lineWidth: 1)
                    )
                    .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                Spacer()
            }
            .padding(.leading, 15)

            ScrollView(.horizontal) {
                HStack {
                    ForEach(clothingCategories, id: \.id) { category in
                        CategoryButton(
                            clothingCategory: category,
                            // Loģika kategoriju atlasei
                            isSelected: selectedCategories.contains(category.id),
                            onLongPress: { selected in
                                selectedCategory = selected
                                selectedClothingItem = nil
                                actionSheetType = .category
                                showActionSheet = true
                            },
                            toggleSelection: toggleCategorySelection
                        )
                    }
                }
                .padding(5)
            }
            .padding(.horizontal, 10)
        }
    }

    // MARK: - Apģērbu sadaļa

    private var clothingItemsSection: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Apģērbi")
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .bold()
                    .background(Color(.white))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(.black), lineWidth: 1)
                    )
                    .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                Spacer()
            }
            .padding(.leading, 15)

            // Meklēšanas lauks un filtru poga
            HStack {
                TextField("Meklēt", text: $searchTextObservable.searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)

                Button(action: {
                    showFilterSheet = true
                }) {
                    ZStack {
                        if isFilterActive {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 35, height: 35)
                        }
                        Image(systemName: "slider.horizontal.3")
                            .resizable()
                            .frame(width: 25, height: 20)
                            .foregroundColor(isFilterActive ? .blue : .black)
                            .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                    }
                }
                .padding(.trailing)
            }

            // Attēli tiek attēloti režģī, kas pielāgojas ekrāna izmēram
            ScrollView {
                ZStack {
                    // Loģika, kas gaida pieskārienu tukšumā, lai izietu no atlases režīma
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
                            clothingItemButton(
                                clothingItem: item,
                                isSelected: selectedClothingItemsIDs.contains(item.id),
                                onTap: {
                                    if isSelectionModeActive {
                                        toggleClothingItemSelection(item)
                                    } else {
                                        // Attēla detalizētais skats tiek parādīts tad, ja nav aktivizēts atlases režīms
                                        selectedClothingItem = item
                                        showClothingItemDetail = true
                                    }
                                },
                                // Turot kādu attēlu, tiek iespējots atlases režīms
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
                // Apģērba detalizētā skata attēlošana
                if let item = selectedClothingItem {
                    clothingItemDetailView(
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
        }
    }

    // MARK: - ActionSheet pārvalde

    // Ģenerē attiecīgo lapu balstoties uz actionSheetType vērtību
    private func getActionSheet() -> ActionSheet {
        switch actionSheetType {
        case .category:
            return categoryActionSheet()
        case .clothingItem, .clothingItemOptions:
            return clothingItemActionSheet()
        case .addOptions:
            return addOptionsActionSheet()
        case .none:
            return ActionSheet(title: Text("No Action"))
        }
    }

    // Ģenerē pievienošanas lapu
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

    // Ģenerē kategorijas pārvaldīšanas lapu
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

    // Ģenerē apģērba pārvaldīšanas lapu
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

    // MARK: - Filtrēšanas funkcijas

    // Asinhroni filtrē apģērbus balstoties uz atlasītajiem filtriem
    func performFiltering() {
        DispatchQueue.global(qos: .userInitiated).async {
            let result = clothingItems.filter { item in
                // Apply filtering conditions
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

    // MARK: - Izvēlēto apģērbu pārvaldība

    // Maina apģērba izvēlētais parametru
    /// - Parameter clothingItem: Apģērbs, kuram mainīt parametru
    private func toggleClothingItemSelection(_ clothingItem: ClothingItem) {
        if selectedClothingItemsIDs.contains(clothingItem.id) {
            selectedClothingItemsIDs.remove(clothingItem.id)
        } else {
            selectedClothingItemsIDs.insert(clothingItem.id)
        }

        // Iziet, ja nav izvēlētu apģērbu
        if selectedClothingItemsIDs.isEmpty {
            isSelectionModeActive = false
        }
    }

    // Maina kategorijas izvēlētais parametru
    /// - Parameter kategorija: Kategorija, kurai mainīt parametru
    private func toggleCategorySelection(_ kategorija: ClothingCategory) {
        if selectedCategories.contains(kategorija.id) {
            selectedCategories.remove(kategorija.id)
        } else {
            selectedCategories.insert(kategorija.id)
        }
    }

    // MARK: - Darbību pārvalde

    // Pārvalda izvēlēto apģērbu stāvokli tīrs/netīrs/mazgājas
    /// - Parameter status: Jaunais statuss ("tirs", "netirs", "mazgajas").
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
        isSelectionModeActive = false // Iziet no atlases režīma
        do {
            try modelContext.save()
        } catch {
            // Kļūdas pārvaldība
            errorMessage = "Neizdevās atjaunināt statusu"
            showErrorAlert = true
        }
    }

    // Izdzēš tikai kategoriju, noņem tās apģērbiem to no kategoriju saraksta
    private func removeCategoryOnly() {
        if let category = selectedCategory {
            for item in category.categoryClothingItems {
                item.clothingItemCategories.removeAll { $0 == category }
            }
            modelContext.delete(category)
            do {
                try modelContext.save()
            } catch {
                // Kļūdas pārvaldība
                errorMessage = "Neizdevās dzēst kategoriju"
                showErrorAlert = true
            }
            selectedCategory = nil
        }
    }

    // Izdzēš kategoriju ar visiem tās apģērbiem
    private func deleteCategoryAndItems() {
        if let category = selectedCategory {
            for item in category.categoryClothingItems {
                modelContext.delete(item)
            }
            modelContext.delete(category)
            do {
                try modelContext.save()
            } catch {
                // Kļūdas pārvaldība
                errorMessage = "Neizdevās dzēst kategoriju un apģērbus"
                showErrorAlert = true
            }
            selectedCategory = nil
            performFiltering()
        }
    }

    // Izvēlētā apģērba dzēšana
    private func deleteSelectedClothingItem() {
        // Situācija 1: Izvēlēts viens apģērbs
        if let single = selectedClothingItem {
            selectedClothingItem = nil
            showClothingItemDetail = false

            DispatchQueue.main.async {
                modelContext.delete(single)
                do {
                    try modelContext.save()
                    performFiltering()
                } catch {
                    // Kļūdas pārvaldība
                    errorMessage = "Neizdevās dzēst apģērbu"
                    showErrorAlert = true
                }
            }
        }
        // Situācija 2: Izvēlēti vairāki apģērbi
        else if !selectedClothingItemsIDs.isEmpty {
            DispatchQueue.main.async {
                // Iet cauri visiem apģērbiem, un dzēš izvēlētos
                for item in clothingItems where selectedClothingItemsIDs.contains(item.id) {
                    modelContext.delete(item)
                }
                selectedClothingItemsIDs.removeAll()
                isSelectionModeActive = false // Iziet no atlases režīma
                do {
                    try modelContext.save()
                    performFiltering()
                } catch {
                    // Kļūdas pārvaldība
                    errorMessage = "Neizdevās dzēst izvēlētos apģērbus"
                    showErrorAlert = true
                }
            }
        }
    }
}



