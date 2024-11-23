//
//  ContentView.swift
//  Keitas Skapis
//
//  Created by Henrijs Obolevics on 31/08/2024.
//

import SwiftUI
import SwiftData


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

    enum ActionSheetType {
        case kategorija, apgerbs
    }

    var body: some View {
        NavigationStack {
            VStack {
                // Header
                HStack {
                    Text("Keitas Skapis").font(.title).bold()
                    Spacer()
                    Button(action: {
                        showActionSheet = true
                    }) {
                        Image(systemName: "plus")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .bold()
                            .foregroundStyle(.black)
                    }
                }
                .padding()

                // Categories Section
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
                            .background(selectedKategorijas.contains(kategorija.id) ? Color.blue.opacity(0.3) : Color.gray.opacity(0.50))
                            .cornerRadius(8)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                toggleKategorijaSelection(kategorija)
                            }
                            .onLongPressGesture {
                                selectedKategorija = kategorija
                                actionSheetType = .kategorija
                                showActionSheet = true
                            }
                        }
                    }
                }
                .padding(.horizontal, 10)

                // Search Bar with Filter Button
                HStack {
                    TextField("Search for items...", text: $searchText)
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

                // Clothing Items Section
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 90, maximum: 120))], spacing: 10) {
                        ForEach(filteredApgerbi, id: \.id) { apgerbs in
                            VStack {
                                if let image = apgerbs.displayedImage {
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

                                Text(apgerbs.nosaukums)
                                    .frame(width: 80, height: 30)
                            }
                            .frame(width: 90, height: 120)
                            .background(Color.gray.opacity(0.50))
                            .cornerRadius(8)
                            .contentShape(Rectangle())
                            .onLongPressGesture {
                                selectedApgerbs = apgerbs
                                actionSheetType = .apgerbs
                                showActionSheet = true
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Image("wardrobe_background")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .blur(radius: 5)
                .edgesIgnoringSafeArea(.all)
            )
            .actionSheet(isPresented: $showActionSheet) {
                switch actionSheetType {
                case .kategorija:
                    return kategorijaActionSheet()
                case .apgerbs:
                    return apgerbsActionSheet()
                case .none:
                    return ActionSheet(title: Text("Error"))
                }
            }
            .onAppear {
                allColors = Array(Set(apgerbi.map { $0.krasa }))
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
            .navigationDestination(isPresented: $isEditing) {
                if let kategorija = selectedKategorija {
                    PievienotKategorijuView(existingKategorija: kategorija)
                } else if let apgerbs = selectedApgerbs {
                    PievienotApgerbuView(existingApgerbs: apgerbs)
                }
            }
            .preferredColorScheme(.light)
        }
    }

    // Filtered Apgerbs Logic
    var filteredApgerbi: [Apgerbs] {
        apgerbi.filter { apgerbs in
            (selectedKategorijas.isEmpty || apgerbs.kategorijas.contains { selectedKategorijas.contains($0.id) }) &&
            (selectedColors.isEmpty || selectedColors.contains(apgerbs.krasa)) &&
            (selectedSizes.isEmpty || selectedSizes.contains(apgerbs.izmers)) &&
            (selectedSeasons.isEmpty || !Set(apgerbs.sezona).intersection(selectedSeasons).isEmpty) &&
            (selectedLastWorn == nil || apgerbs.pedejoreizVilkts <= selectedLastWorn!) &&
            (isIronable == nil || apgerbs.gludinams == isIronable) &&
            (isLaundering == nil || apgerbs.mazgajas == isLaundering) &&
            (isDirty == nil || apgerbs.netirs == isDirty)
        }.filter {
            searchText.isEmpty || $0.nosaukums.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func kategorijaActionSheet() -> ActionSheet {
        ActionSheet(
            title: Text("Manage \(selectedKategorija?.nosaukums ?? "")"),
            message: Text("This category contains \(selectedKategorija?.apgerbi.count ?? 0) items."),
            buttons: [
                .default(Text("Edit")) {
                    isEditing = true
                },
                .default(Text("Delete Category Only")) {
                    removeKategorijaOnly()
                },
                .destructive(Text("Delete Category and Items")) {
                    deleteKategorijaAndItems()
                },
                .cancel()
            ]
        )
    }

    private func apgerbsActionSheet() -> ActionSheet {
        ActionSheet(
            title: Text("Manage \(selectedApgerbs?.nosaukums ?? "")"),
            buttons: [
                .default(Text("Edit")) {
                    isEditing = true
                },
                .destructive(Text("Delete")) {
                    deleteSelectedApgerbs()
                },
                .cancel()
            ]
        )
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
                Section(header: Text("Colors")) {
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
                Section(header: Text("Sizes")) {
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
                Section(header: Text("Seasons")) {
                    DisclosureGroup(isExpanded: $isSeasonDropdownExpanded) {
                        ForEach(allSeasons, id: \.self) { season in
                            Toggle(season.rawValue, isOn: Binding(
                                get: { selectedSeasons.contains(season) },
                                set: { isSelected in toggleSeasonSelection(season, isSelected: isSelected) }
                            ))
                        }
                    } label: {
                        Text("Select Seasons")
                    }
                }

                // Last Worn Filter
                Section(header: Text("Last Worn")) {
                    DatePicker("Before", selection: Binding(
                        get: { selectedLastWorn ?? Date() },
                        set: { newValue in selectedLastWorn = newValue }
                    ), displayedComponents: .date)
                }

                // Laundering and Dirty Filters
                Section(header: Text("Laundry Status")) {
                    Toggle("Ironable", isOn: Binding(
                        get: { isIronable ?? false },
                        set: { newValue in isIronable = newValue }
                    ))
                    Toggle("Laundering", isOn: Binding(
                        get: { isLaundering ?? false },
                        set: { newValue in isLaundering = newValue }
                    ))
                    Toggle("Dirty", isOn: Binding(
                        get: { isDirty ?? false },
                        set: { newValue in isDirty = newValue }
                    ))
                }

                // Clear Filters Button
                Section {
                    Button(action: clearFilters) {
                        Text("Clear All Filters")
                            .foregroundColor(.red)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Filters")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
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
