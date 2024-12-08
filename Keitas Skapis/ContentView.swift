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
    @Environment(\.modelContext) private var modelContext
    
    @Query private var kategorijas: [Kategorija]
    @Query private var apgerbi: [Apgerbs]

    @StateObject private var viewModel = ContentViewModel()
    @StateObject private var searchTextObservable = SearchTextObservable()

    // UI States
    @State private var selectedApgerbs: Apgerbs? = nil
    @State private var selectedApgerbsIDs: Set<UUID> = []
    @State private var selectedKategorija: Kategorija? = nil
    @State private var actionSheetType: ActionSheetType? = nil
    @State private var showActionSheet = false
    @State private var isEditing = false
    @State private var isAddingKategorija = false
    @State private var isAddingApgerbs = false
    @State private var showFilterSheet = false
    @State private var showApgerbsDetail = false

    enum ActionSheetType {
        case apgerbsOptions, kategorija, apgerbs, addOptions
    }

    var body: some View {
        NavigationStack {
            VStack {
                headerView
                categoriesView
                searchBarAndFilterButton
                itemsGrid
            }
            .background(
                Image("wardrobe_background")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .blur(radius: 5)
                    .edgesIgnoringSafeArea(.all)
            )
            .actionSheet(isPresented: $showActionSheet) {
                actionSheetForType(actionSheetType)
            }
            .sheet(isPresented: $showFilterSheet) {
                FilterSelectionView(
                    selectedColors: $viewModel.selectedColors,
                    selectedSizes: $viewModel.selectedSizes,
                    selectedSeasons: $viewModel.selectedSeasons,
                    selectedLastWorn: $viewModel.selectedLastWorn,
                    isIronable: $viewModel.isIronable,
                    isLaundering: $viewModel.isLaundering,
                    isDirty: $viewModel.isDirty,
                    allColors: viewModel.allColors
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
            .onAppear {
                // Initialize the ViewModel with apgerbi once it appears
                viewModel.setInitialData(apgerbi)
            }
            // Update viewModel's debouncedSearchText whenever the search input changes
            .onChange(of: searchTextObservable.debouncedSearchText) { oldValue, newValue in
                viewModel.debouncedSearchText = newValue
            }
            .preferredColorScheme(.light)
        }
    }

    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            Text("Keitas Skapis")
                .font(.title).bold()
            Spacer()
            if !selectedApgerbsIDs.isEmpty {
                Button(action: {
                    actionSheetType = .apgerbsOptions
                    showActionSheet = true
                }) {
                    Image(systemName: "pencil")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundStyle(.black)
                }
            }

            Button(action: {
                actionSheetType = .addOptions
                showActionSheet = true
            }) {
                Image(systemName: "plus")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(.black)
            }
        }
        .padding()
    }

    private var categoriesView: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(kategorijas, id: \.id) { kategorija in
                    VStack {
                        if let image = kategorija.displayedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .padding(.top, 5)
                                .padding(.bottom, -10)
                        } else {
                            // Fallback image
                            Image(systemName: "rectangle.portrait.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .foregroundStyle(.gray)
                                .opacity(0.5)
                                .padding(.top, 5)
                                .padding(.bottom, -10)
                        }

                        Text(kategorija.nosaukums)
                            .frame(width: 80, height: 30)
                    }
                    .frame(width: 90, height: 120)
                    // Use the viewModel's selectedKategorijas for highlighting
                    .background(viewModel.selectedKategorijas.contains(kategorija.id) ? Color.blue.opacity(0.3) : Color.gray.opacity(0.5))
                    .cornerRadius(8)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        toggleKategorijaSelection(kategorija)
                    }
                    .simultaneousGesture(
                        LongPressGesture().onEnded { _ in
                            selectedKategorija = kategorija
                            selectedApgerbs = nil
                            actionSheetType = .kategorija
                            showActionSheet = true
                        }
                    )
                }
            }
        }
        .padding(.horizontal, 10)
    }

    private var searchBarAndFilterButton: some View {
        HStack {
            TextField("Meklēt apģērbu...", text: $searchTextObservable.searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            Button(action: {
                showFilterSheet = true
            }) {
                Image(systemName: "slider.horizontal.3")
                    .resizable()
                    .frame(width: 20, height: 20)
            }
            .padding(.trailing)
        }
        .padding(.bottom, 5)
    }

    private var itemsGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90, maximum: 120))], spacing: 10) {
                // Now referencing viewModel.filteredApgerbi
                ForEach(viewModel.filteredApgerbi, id: \.id) { apgerbs in
                    VStack {
                        AsyncImageView(apgerbs: apgerbs)
                            .frame(width: 80, height: 80)
                            .padding(.top, 5)
                            .padding(.bottom, -10)
                        Text(apgerbs.nosaukums)
                            .frame(width: 80, height: 30)
                    }
                    .frame(width: 90, height: 120)
                    .background(selectedApgerbsIDs.contains(apgerbs.id) ? Color.blue.opacity(0.3) : Color.gray.opacity(0.5))
                    .cornerRadius(8)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedApgerbs = apgerbs
                        showApgerbsDetail = true
                    }
                    .simultaneousGesture(
                        LongPressGesture().onEnded { _ in
                            toggleApgerbsSelection(apgerbs)
                        }
                    )
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
                        }
                    }
                }
            }
        }
        .padding()
    }

    // MARK: - Actions and Sheets

    private func actionSheetForType(_ type: ActionSheetType?) -> ActionSheet {
        switch type {
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
                .cancel()
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
        if let apgerbs = selectedApgerbs {
            modelContext.delete(apgerbs)
            selectedApgerbs = nil
            try? modelContext.save()
        } else {
            for apgerbs in apgerbi where selectedApgerbsIDs.contains(apgerbs.id) {
                modelContext.delete(apgerbs)
            }
            selectedApgerbsIDs.removeAll()
            try? modelContext.save()
        }
    }

    private func toggleKategorijaSelection(_ kategorija: Kategorija) {
        if viewModel.selectedKategorijas.contains(kategorija.id) {
            viewModel.selectedKategorijas.remove(kategorija.id)
        } else {
            viewModel.selectedKategorijas.insert(kategorija.id)
        }
    }
}

// MARK: - Supporting AsyncImageView and ApgerbsDetailView unchanged

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
                ProgressView()
            }
        }
    }
}

struct ApgerbsDetailView: View {
    let apgerbs: Apgerbs
    var onEdit: () -> Void
    var onDelete: () -> Void

    @State private var selectedStavoklis: String

    init(apgerbs: Apgerbs, onEdit: @escaping () -> Void, onDelete: @escaping () -> Void) {
        self.apgerbs = apgerbs
        self.onEdit = onEdit
        self.onDelete = onDelete
        _selectedStavoklis = State(initialValue: apgerbs.netirs ? "Netīrs" : (apgerbs.mazgajas ? "Mazgājas" : "Tīrs"))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Name
                Text(apgerbs.nosaukums)
                    .font(.title)
                    .bold()
                    .padding(.top, 20)

                // Last Worn
                Text("Pēdējoreiz vilkts: \(formattedDate(apgerbs.pedejoreizVilkts))")
                    .font(.subheadline)

                // Image
                AsyncImageView(apgerbs: apgerbs)
                    .frame(height: 200)

                Text(apgerbs.piezimes)
                
                // Categories
                Text("Kategorijas")
                    .font(.headline)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 70), spacing: 5)], spacing: 5) {
                    ForEach(apgerbs.kategorijas, id: \.id) { kategorija in
                        Text(kategorija.nosaukums)
                            .lineLimit(1) // Prevents wrapping
                            .truncationMode(.tail) // Truncates text with ellipsis
                            .padding(8)
                            .frame(minWidth: 70) // Ensures consistent size
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                    }
                }

                // Stāvoklis
                HStack {
                    Text("Stāvoklis: ").bold()
                    Text("\(selectedStavoklis)")
                        .bold()
                        .foregroundColor(colorForStavoklis(selectedStavoklis))
                }

                // Color, Size, Gludinams
                HStack {
                    HStack {
                        Text("Krāsa: ").bold()
                        Circle()
                            .fill(apgerbs.krasa.color)
                            .frame(width: 24, height: 24)
                    }
                    Spacer()
                    Text("Izmērs: \(sizeLetter(for: apgerbs.izmers))")
                        .bold()
                    Spacer()
                    Text(apgerbs.gludinams ? "Gludināms" : "Negludināms")
                        .foregroundColor(apgerbs.gludinams ? .green : .red).bold()
                }

                // Seasons
                Text("Sezonas")
                    .font(.headline)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 70), spacing: 5)], spacing: 5) {
                    ForEach(apgerbs.sezona, id: \.self) { sezona in
                        Text(sezona.rawValue)
                            .padding(8)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                    }
                }

                // Picker for Stavoklis
                Text("Stāvoklis").bold()
                
                Picker("Stāvoklis", selection: $selectedStavoklis) {
                    Text("Tīrs").tag("Tīrs")
                    Text("Netīrs").tag("Netīrs")
                    Text("Mazgājas").tag("Mazgājas")
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: selectedStavoklis) { _, newValue in
                    updateStavoklis(newValue)
                }

                // Edit and Delete Buttons
                HStack {
                    Button(action: onEdit) {
                        Text("Rediģēt")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }

                    Button(action: onDelete) {
                        Text("Dzēst")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding(.top, 20)

                Spacer()
            }
            .padding()
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func sizeLetter(for size: Int) -> String {
        switch size {
        case 0: return "XS"
        case 1: return "S"
        case 2: return "M"
        case 3: return "L"
        case 4: return "XL"
        default: return "Nezināms"
        }
    }

    private func colorForStavoklis(_ stavoklis: String) -> Color {
        switch stavoklis {
        case "Tīrs":
            return .green
        case "Netīrs":
            return .red
        case "Mazgājas":
            return .yellow
        default:
            return .gray
        }
    }

    private func updateStavoklis(_ newValue: String) {
        switch newValue {
        case "Tīrs":
            apgerbs.netirs = false
            apgerbs.mazgajas = false
        case "Netīrs":
            apgerbs.netirs = true
            apgerbs.mazgajas = false
        case "Mazgājas":
            apgerbs.netirs = false
            apgerbs.mazgajas = true
        default:
            break
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
                                        .stroke(selectedColors.contains(color) ? Color.blue : Color.clear, lineWidth: 3)
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



//        ZStack {
//            Image("wardrobe_background")
//                .resizable()
//                .aspectRatio(contentMode: .fill)
//                .blur(radius: 5)
//                .edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
//            VStack {
//                Text("Keitas Skapis")
//                    .font(Font.custom("DancingScript-Bold", size: 48))
//                    .foregroundStyle(.white)
//                    .shadow(color: .black, radius: 8, x: 2, y: 5)
//                Spacer()
//
//                    Image(systemName: "plus.app.fill").resizable().frame(width: 40, height: 40).foregroundStyle(.white).bold().opacity(0.85).padding([.bottom], 5).padding([.top], -30)
//
//
//                VStack {
//                    HStack {
//                        ZStack {
//                            Image(systemName: "rectangle.portrait.fill").resizable().frame(width: 100, height: 150).foregroundStyle(.white).opacity(0.8)
//                            VStack {
//                                Image("dress").resizable().frame(width: 50, height: 50)
//                                Text("Kleitas").bold()
//                            }
//                        }
//                        ZStack {
//                            Image(systemName: "rectangle.portrait.fill").resizable().frame(width: 100, height: 150).foregroundStyle(.white).opacity(0.8)
//                            VStack {
//                                Image("dress").resizable().frame(width: 50, height: 50)
//                                Text("Kleitas").bold()
//                            }
//                        }
//                        ZStack {
//                            Image(systemName: "rectangle.portrait.fill").resizable().frame(width: 100, height: 150).foregroundStyle(.white).opacity(0.8)
//                            VStack {
//                                Image("dress").resizable().frame(width: 50, height: 50)
//                                Text("Kleitas").bold()
//                            }
//                        }
//                    }
//                    HStack {
//                        ZStack {
//                            Image(systemName: "rectangle.portrait.fill").resizable().frame(width: 100, height: 150).foregroundStyle(.white).opacity(0.8)
//                            VStack {
//                                Image("dress").resizable().frame(width: 50, height: 50)
//                                Text("Kleitas").bold()
//                            }
//                        }
//                        ZStack {
//                            Image(systemName: "rectangle.portrait.fill").resizable().frame(width: 100, height: 150).foregroundStyle(.white).opacity(0.8)
//                            VStack {
//                                Image("dress").resizable().frame(width: 50, height: 50)
//                                Text("Kleitas").bold()
//                            }
//                        }
//                        ZStack {
//                            Image(systemName: "rectangle.portrait.fill").resizable().frame(width: 100, height: 150).foregroundStyle(.white).opacity(0.8)
//                            VStack {
//                                Image("dress").resizable().frame(width: 50, height: 50)
//                                Text("Kleitas").bold()
//                            }
//                        }
//                    }
//                    HStack {
//                        ZStack {
//                            Image(systemName: "rectangle.portrait.fill").resizable().frame(width: 100, height: 150).foregroundStyle(.white).opacity(0.8)
//                            VStack {
//                                Image("dress").resizable().frame(width: 50, height: 50)
//                                Text("Kleitas").bold()
//                            }
//                        }
//                        ZStack {
//                            Image(systemName: "rectangle.portrait.fill").resizable().frame(width: 100, height: 150).foregroundStyle(.white).opacity(0.8)
//                            VStack {
//                                Image("dress").resizable().frame(width: 50, height: 50)
//                                Text("Kleitas").bold()
//                            }
//                        }
//                        ZStack {
//                            Image(systemName: "rectangle.portrait.fill").resizable().frame(width: 100, height: 150).foregroundStyle(.white).opacity(0.8)
//                            VStack {
//                                Image("dress").resizable().frame(width: 50, height: 50)
//                                Text("Kleitas").bold()
//                            }
//                        }
//                    }
//                }
//                Spacer()
//                HStack (spacing: 250) {
//                    VStack {
//                      Button(action: {
//                          showOutfit.toggle()
//                      }) {
//                          Image(systemName: "figure.child").resizable().frame(width: 35, height: 45).foregroundStyle(.white).opacity(0.8)
//                      }.sheet(isPresented: $showOutfit) {
//                          VStack {
//                              Text("Outfit").font(.title).bold().frame(maxWidth: 350, alignment: .leading)
//                              ScrollView (showsIndicators: false) {
//                                  Image("shirt").resizable().frame(width: 180, height: 180)
//                                  Image("pants").resizable().frame(width: 180, height: 180)
//                                  Image("socks").resizable().frame(width: 180, height: 180)
//                                  Image("shoes").resizable().frame(width: 180, height: 180)
//                              }
//                          }
//                          .presentationDetents([.large])
//                          .padding(.top, 30)
//                      }
//                    }
//
//                    VStack {
//                      Button(action: {
//                          showList.toggle()
//                      }) {
//                          Image(systemName: "list.bullet.rectangle.fill").resizable().frame(width: 30, height: 35).foregroundStyle(.white).opacity(0.8)
//                      }.sheet(isPresented: $showList) {
//                          VStack {
//                              Text("Picked Items").font(.title).bold().frame(maxWidth: 350, alignment: .leading).padding(.bottom, 10)
//                              ScrollView (showsIndicators: false) {
//                                  HStack (spacing: 60) {
//                                      Image("dress").resizable().frame(width: 50, height: 50)
//                                      Text("Tommy Kleita").font(.title3).bold()
//                                      Image(systemName: "trash").resizable().frame(width: 25, height: 25).foregroundStyle(.gray)
//                                  }.padding(.bottom, 15)
//                              }
//
//                          }
//                          .presentationDetents([.fraction(0.40), .fraction(0.75)])
//                          .padding(.top, 30)
//                      }
//                    }
//                }
//            }
//            .padding()
//        }
