
import SwiftUI
import SwiftData
import Combine

struct FavoritesView: View {
    // MARK: - Vides mainīgie

    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext

    // MARK: - Datu vaicājumi

    @Query private var clothingItems: [ClothingItem]

    // MARK: - Stāvokļu mainīgie

    @State private var selectedClothingItemsIDs: Set<UUID> = []
    @State private var isSelectionModeActive = false
    @State private var showActionSheet = false
    @State private var actionSheetType: ActionSheetType?
    @State private var showClothingItemDetail = false
    @State private var selectedClothingItem: ClothingItem?
    @State private var isEditing = false
    
    // MARK: - Kļūdu apstrādes mainīgie
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""

    // MARK: - Enums

    // Enum, kas norāda, kādu lapu parādīt
    enum ActionSheetType {
        case clothingItemOptions
    }

    // MARK: - Aprēķināmās vērtības

    // Filtrē apģērbus, lai parādītu tikai mīļākos
    private var favoriteClothingItems: [ClothingItem] {
        clothingItems.filter { $0.isFavorite }
    }

    // MARK: - Galvenais saturs

    var body: some View {
        NavigationStack {
            VStack {
                // Galvene
                HStack {
                    Text("Mīļākie")
                        .font(.title)
                        .bold()
                        .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)

                    Spacer()

                    // Poga, kas parādās tikai atlases režīmā
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
                        }
                    }
                }
                .navigationBarBackButtonHidden(true)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.black), lineWidth: 1))
                .padding(.horizontal, 10)
                .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)

                ScrollView {
                    ZStack {
                        // Pieskāriena reģistrācija tukšumā, lai izietu no atlases režīma
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if isSelectionModeActive {
                                    isSelectionModeActive = false
                                    selectedClothingItemsIDs.removeAll()
                                }
                            }

                        // Režģis ar attēliem
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 90, maximum: 120))],
                            spacing: 10
                        ) {
                            ForEach(favoriteClothingItems, id: \.id) { item in
                                // Poga apģērba attēlošanai
                                clothingItemButton(
                                    clothingItem: item,
                                    isSelected: selectedClothingItemsIDs.contains(item.id),
                                    onTap: {
                                        if isSelectionModeActive {
                                            toggleClothingItemSelection(item) // Palīgfunkcija
                                        } else {
                                            selectedClothingItem = item
                                            showClothingItemDetail = true
                                        }
                                    },
                                    onLongPress: {
                                        if !isSelectionModeActive {
                                            isSelectionModeActive = true
                                        }
                                        toggleClothingItemSelection(item) // Palīgfunkcija
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Image("background_dmitriy_steinke").resizable().edgesIgnoringSafeArea(.all).opacity(0.3))

            // MARK: - ToolBar
            // Rīkjosla
            ToolBar()
                .background(Color(.systemGray5))
                .padding(.top, -10)

            // Apģērba detaļu skats
            .sheet(isPresented: $showClothingItemDetail) {
                if let clothingItem = selectedClothingItem {
                    clothingItemDetailView(
                        clothingItem: clothingItem,
                        onEdit: {
                            showClothingItemDetail = false
                            isEditing = true
                        },
                        onDelete: {
                            deleteSelectedClothingItem() // Palīgfunkcija
                            showClothingItemDetail = false
                        }
                    )
                } else {
                    Text("Nav izvēlēts apģērbs")
                }
            }

            // Saite uz attēla rediģēšanu
            .navigationDestination(isPresented: $isEditing) {
                if let clothingItem = selectedClothingItem {
                    PievienotApgerbuView(existingClothingItem: clothingItem)
                        .onDisappear {
                            isEditing = false
                        }
                }
            }
            
            // Kļūdas paziņojums
            .alert(isPresented: $showErrorAlert) {
                Alert(
                    title: Text("Kļūda!"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }

            // Lapa apģērbu pārvaldībai
            .actionSheet(isPresented: $showActionSheet) {
                switch actionSheetType {
                case .clothingItemOptions:
                    return clothingItemActionSheet() // Palīgfunkcija
                case .none:
                    return ActionSheet(title: Text("Nav darbību"))
                }
            }
            .preferredColorScheme(.light)
        }
    }

    // MARK: - Lapa apģērbu pārvaldībai

    // Izveido lapu apģērbu pārvaldībai
    /// - Returns: `ActionSheet` ar dažādām opcijām.
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

    // Maina apģērba izvēles statusu
    /// - Parameter clothingItem: Apģērbs.
    private func toggleClothingItemSelection(_ clothingItem: ClothingItem) {
        if selectedClothingItemsIDs.contains(clothingItem.id) {
            selectedClothingItemsIDs.remove(clothingItem.id)
        } else {
            selectedClothingItemsIDs.insert(clothingItem.id)
        }
        if selectedClothingItemsIDs.isEmpty {
            isSelectionModeActive = false
        }
    }

    // Pārvalda izvēlēto apģērbu stāvokli tīrs/netīrs/mazgājas
    /// - Parameter status: jaunais statuss ("tirs", "netirs", "mazgajas").
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
            errorMessage = "Failed to update clothing item status."
            showErrorAlert = true
        }
    }


    // Izdzēš izvēlēto apģērbu(us)
    private func deleteSelectedClothingItem() {
        // Situācija 1: Izvēlēts viens apģērbs
        if let single = selectedClothingItem {
            selectedClothingItem = nil
            showClothingItemDetail = false

            DispatchQueue.main.async {
                modelContext.delete(single)
                do {
                    try modelContext.save()
                    // performFiltering() // Not needed if no filtering
                } catch {
                    // Kļūdas pārvaldība
                    errorMessage = "Failed to delete clothing item."
                    showErrorAlert = true
                }
            }
        }
        // Situācija 2: Izvēlēti vairāki apģērbi
        else if !selectedClothingItemsIDs.isEmpty {
            DispatchQueue.main.async {
                // Iet cauri visiem apģērbiem un dzēš izvēlētos
                for item in clothingItems where selectedClothingItemsIDs.contains(item.id) {
                    modelContext.delete(item)
                }
                selectedClothingItemsIDs.removeAll()
                isSelectionModeActive = false // Iziet no atlases režīma
                do {
                    try modelContext.save()
                    // performFiltering() // Not needed if no filtering
                } catch {
                    // Kļūdas pārvaldība
                    errorMessage = "Failed to delete selected clothing items."
                    showErrorAlert = true
                }
            }
        }
    }
}




