
import SwiftUI
import SwiftData
import Combine

// MARK: - Netīro un mazgāšanā esošo apģērbu skats
struct DirtyClothingItemsView: View {
    // MARK: - Vides mainīgie un datu vaicājumi
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var clothingItems: [ClothingItem]

    // MARK: - Stāvokļu mainīgie
    @State private var showDirty = true
    @State private var selectedClothingItemsIDs: Set<UUID> = []
    @State private var showActionSheet = false
    @State private var actionSheetType: ActionSheetType?
    @State private var showClothingItemDetail = false
    @State private var selectedClothingItem: ClothingItem?
    @State private var isSelectionModeActive = false
    @State private var isEditing = false
    
    // MARK: - Kļūdu apstrādes mainīgie
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""


    // Lapu veidi
    enum ActionSheetType {
        case clothingItemOptions
    }

    // Filtrē apģērbus balstoties uz to stāvokli
    var filteredClothingItems: [ClothingItem] {
        clothingItems.filter { item in
            if showDirty {
                return item.dirty == true
            } else {
                return item.washing == true
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                // Augšpusē ir izvēle rādīt netīros vai mazgāšanā esošos apģērbus
                HStack(spacing: 20) {
                    Text("Netīrie")
                        .font(.title).bold()
                        .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                        .foregroundColor(showDirty ? .blue : .primary)
                        .onTapGesture {
                            showDirty = true
                        }

                    Text("Mazgājas")
                        .font(.title).bold()
                        .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                        .foregroundColor(!showDirty ? .blue : .primary)
                        .onTapGesture {
                            showDirty = false
                        }
                        .navigationBarBackButtonHidden(true)
                    
                    Spacer()
                    
                    // Poga, kas parādās atlases režīmā (turot uz kāda apģērba)
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
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.black), lineWidth: 1))
                .padding(.horizontal, 10)
                .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)

                // Režģis ar apģērbiem, kuri izmanto ApgerbsBtn attēlošanai
                ScrollView {
                    ZStack {
                        // Nospiežot uz tukšuma iziet no atlases režīma
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if isSelectionModeActive {
                                    isSelectionModeActive = false
                                    selectedClothingItemsIDs.removeAll()
                                }
                            }
                        
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 90, maximum: 120))],
                            spacing: 10
                        ) {
                            ForEach(filteredClothingItems, id: \.id) { item in
                                clothingItemButton(
                                    clothingItem: item,
                                    isSelected: selectedClothingItemsIDs.contains(item.id),
                                    onTap: {
                                        if isSelectionModeActive {
                                            toggleClothingItemSelection(item) // Palīgfunkcija atlasei uz pieskāriena
                                        } else {
                                            selectedClothingItem = item
                                            showClothingItemDetail = true
                                        }
                                    },
                                    onLongPress: {
                                        if !isSelectionModeActive {
                                            isSelectionModeActive = true
                                        }
                                        toggleClothingItemSelection(item) // Palīgfunkcija atlasei turot uz apģērba
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Image("background_dmitriy_steinke").resizable().edgesIgnoringSafeArea(.all).opacity(0.3))
            ToolBar()
                .background(Color(.systemGray5)).padding(.top, -10)

            // Detaļu lapa apģērbam
            .sheet(isPresented: $showClothingItemDetail) {
                if let item = selectedClothingItem {
                    clothingItemDetailView(
                        clothingItem: item,
                        onEdit: {
                            showClothingItemDetail = false
                            isEditing = true
                        },
                        onDelete: {
                            deleteSelectedClothingItem() // Palīgfunkcija apģērba dzēšanai
                            showClothingItemDetail = false
                        }
                    )
                } else {
                    Text("No Apgerbs Selected")
                }
            }

            // Atver apģērba rediģēšanas skatu
            .navigationDestination(isPresented: $isEditing) {
                if let item = selectedClothingItem {
                    PievienotApgerbuView(existingClothingItem: item)
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

    // MARK: - Palīgfunkcijas

    // Izveido lapu apģērbu pārvaldībai atlases režīmā
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

    // Maina apģērba izvēles statusu, pievienojot/noņemot to sarakstam
    /// - Parameter clothingItem: apģērbs, kuram mainīt statusu
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
            errorMessage = "Neizdevās atjaunināt apģērba statusu"
            showErrorAlert = true
        }
    }


    // Izdzēš izvēlēto apģērbu(us)
    private func deleteSelectedClothingItem() {
        // Situācija 1: Izvēlēti vairāki apģērbi
        if !selectedClothingItemsIDs.isEmpty {
            DispatchQueue.main.async {
                // Iet cauri visiem apģērbiem un dzēš izvēlētos
                for item in clothingItems where selectedClothingItemsIDs.contains(item.id) {
                    modelContext.delete(item)
                }
                selectedClothingItemsIDs.removeAll()
                isSelectionModeActive = false // Iziet no atlases režīma
                do {
                    try modelContext.save()
                    //performFiltering()
                } catch {
                    // Kļūdas pārvaldība
                    errorMessage = "Neizdevās dzēst izvēlētos apģērbus"
                    showErrorAlert = true
                }
            }
        }
        // Situācija 2: Izvēlēts viens apģērbs
        else if let single = selectedClothingItem {
            selectedClothingItem = nil
            showClothingItemDetail = false

            DispatchQueue.main.async {
                modelContext.delete(single)
                do {
                    try modelContext.save()
                    //performFiltering()
                } catch {
                    // Kļūdas pārvaldība
                    errorMessage = "Neizdevās dzēst apģērbu"
                    showErrorAlert = true
                }
            }
        }
    }

}



#Preview {
    DirtyClothingItemsView()
}

