//
//  NetirieApgerbi.swift
//  Keitas Skapis
//
//  Created by Henrijs Obolevics on 10/12/2024.
//

import SwiftUI
import SwiftData
import Combine

struct NetirieApgerbiView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var clothingItems: [ClothingItem]

    @State private var showDirty = true
    @State private var selectedClothingItemsIDs: Set<UUID> = []
    @State private var showActionSheet = false
    @State private var actionSheetType: ActionSheetType?
    @State private var showClothingItemDetail = false
    @State private var selectedClothingItem: ClothingItem?
    @State private var isSelectionModeActive = false
    @State private var isEditing = false

    enum ActionSheetType {
        case clothingItemOptions
    }

    // Filters clothing items based on their dirty or washing status
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
                // Top bar with toggles between "Netīrie" (Dirty) and "Mazgājas" (Washing)
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
                    
                    // Pencil button appears only if some clothing items are selected
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

                // Grid of clothing items using ApgerbsButton
                ScrollView {
                    ZStack {
                        // Tap on empty space exits selection mode
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
                                ApgerbsButton(
                                    clothingItem: item,
                                    isSelected: selectedClothingItemsIDs.contains(item.id),
                                    onTap: {
                                        if isSelectionModeActive {
                                            toggleClothingItemSelection(item) // Helper Function
                                        } else {
                                            selectedClothingItem = item
                                            showClothingItemDetail = true
                                        }
                                    },
                                    onLongPress: {
                                        if !isSelectionModeActive {
                                            isSelectionModeActive = true
                                        }
                                        toggleClothingItemSelection(item) // Helper Function
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

            // Detail Sheet for selected clothing item
            .sheet(isPresented: $showClothingItemDetail) {
                if let item = selectedClothingItem {
                    ApgerbsDetailView(
                        clothingItem: item,
                        onEdit: {
                            showClothingItemDetail = false
                            isEditing = true
                        },
                        onDelete: {
                            deleteSelectedClothingItem(item) // Helper Function
                            showClothingItemDetail = false
                        }
                    )
                } else {
                    Text("No Apgerbs Selected")
                }
            }

            // Navigation to Edit Screen
            .navigationDestination(isPresented: $isEditing) {
                if let item = selectedClothingItem {
                    PievienotApgerbuView(existingClothingItem: item)
                        .onDisappear {
                            isEditing = false
                        }
                }
            }

            // Action Sheet for managing clothing items
            .actionSheet(isPresented: $showActionSheet) {
                switch actionSheetType {
                case .clothingItemOptions:
                    return clothingItemActionSheet() // Helper Function
                case .none:
                    return ActionSheet(title: Text("Nav darbību"))
                }
            }
            .preferredColorScheme(.light)
        }
    }

    // MARK: - Helper Functions

    /// Creates an action sheet with options to manage selected clothing items.
    private func clothingItemActionSheet() -> ActionSheet {
        ActionSheet(
            title: Text("Pārvaldīt apģērbus"),
            buttons: [
                .default(Text("Mainīt uz Tīrs")) {
                    updateClothingItemStatus(to: "tirs") // Helper Function
                },
                .default(Text("Mainīt uz Netīrs")) {
                    updateClothingItemStatus(to: "netirs") // Helper Function
                },
                .default(Text("Mainīt uz Mazgājas")) {
                    updateClothingItemStatus(to: "mazgajas") // Helper Function
                },
                .destructive(Text("Dzēst")) {
                    deleteSelectedClothingItem() // Helper Function
                },
                .cancel()
            ]
        )
    }

    /// Toggles the selection state of a clothing item.
    /// - Parameter clothingItem: The clothing item to toggle.
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

    /// Updates the status of selected clothing items based on the provided status.
    /// - Parameter status: The new status to apply ("tirs", "netirs", "mazgajas").
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
        try? modelContext.save()
    }

    /// Deletes selected clothing items or a single specified item.
    /// - Parameter singleClothingItem: An optional single clothing item to delete.
    private func deleteSelectedClothingItem(_ singleClothingItem: ClothingItem? = nil) {
        if let single = singleClothingItem {
            selectedClothingItem = nil
            showClothingItemDetail = false

            DispatchQueue.main.async {
                modelContext.delete(single)
                try? modelContext.save()
                isSelectionModeActive = false
            }
        } else if !selectedClothingItemsIDs.isEmpty {
            DispatchQueue.main.async {
                for item in clothingItems where selectedClothingItemsIDs.contains(item.id) {
                    modelContext.delete(item)
                }
                selectedClothingItemsIDs.removeAll()
                try? modelContext.save()
                isSelectionModeActive = false
            }
        }
    }
}



#Preview {
    NetirieApgerbiView()
}

