//
//  Favorites.swift
//  Keitas Skapis
//
//  Created by Henrijs Obolevics on 27/12/2024.
//

import SwiftUI
import SwiftData
import Combine

struct FavoritesView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var clothingItems: [ClothingItem]

    // Multi-selection
    @State private var selectedClothingItemsIDs: Set<UUID> = []
    @State private var isSelectionModeActive = false

    // Action Sheet
    @State private var showActionSheet = false
    @State private var actionSheetType: ActionSheetType?

    // Detail
    @State private var showClothingItemDetail = false
    @State private var selectedClothingItem: ClothingItem?

    // Editing flow
    @State private var isEditing = false

    enum ActionSheetType {
        case clothingItemOptions
    }

    // Only show Apgerbs flagged as favorites
    private var favoriteClothingItems: [ClothingItem] {
        clothingItems.filter { $0.isFavorite }
    }

    var body: some View {
        NavigationStack {
            VStack {
                // Top bar
                HStack {
                    Text("Mīļākie").font(.title).bold().shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                    
                    Spacer()
                    
                    // Pencil button if there's a selection
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
                .padding().background(Color(.systemGray6)).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.black), lineWidth: 1)).padding(.horizontal, 10).shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                

                // Grid of favorite Apgerbs using ApgerbsButton
                ScrollView {
                    ZStack {
                        // Detect tap on empty space to exit selection
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
                            ForEach(favoriteClothingItems, id: \.id) { item in
                                ApgerbsButton(
                                    clothingItem: item,
                                    isSelected: selectedClothingItemsIDs.contains(item.id),
                                    onTap: {
                                        if isSelectionModeActive {
                                            toggleClothingItemSelection(item)
                                        } else {
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
            }
            .background(Image("background_dmitriy_steinke").resizable().edgesIgnoringSafeArea(.all).opacity(0.3))
            ToolBar()
            .background(Color(.systemGray5)).padding(.top, -10)
            .sheet(isPresented: $showClothingItemDetail) {
                if let clothingItem = selectedClothingItem {
                    ApgerbsDetailView(
                        clothingItem: clothingItem,
                        onEdit: {
                            // Same pattern as NetirieApgerbiView
                            showClothingItemDetail = false
                            isEditing = true
                        },
                        onDelete: {
                            deleteSelectedClothingItem(clothingItem)
                            showClothingItemDetail = false
                        }
                    )
                } else {
                    Text("Nav izvēlēts apģērbs")
                }
            }
            .navigationDestination(isPresented: $isEditing) {
                if let clothingItem = selectedClothingItem {
                    PievienotApgerbuView(existingClothingItem: clothingItem)
                        .onDisappear {
                            isEditing = false
                        }
                }
            }
            .actionSheet(isPresented: $showActionSheet) {
                switch actionSheetType {
                case .clothingItemOptions:
                    return clothingItemActionSheet()
                case .none:
                    return ActionSheet(title: Text("Nav darbību"))
                }
            }
            .preferredColorScheme(.light)
        }
    }

    // MARK: - Action Sheet & Selection
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
        if selectedClothingItemsIDs.isEmpty {
            isSelectionModeActive = false
        }
    }

    private func updateClothingItemStatus(to status: String) {
        for clothingItem in favoriteClothingItems where selectedClothingItemsIDs.contains(clothingItem.id) {
            switch status {
            case "tirs":
                clothingItem.dirty = false
                clothingItem.washing = false
            case "netirs":
                clothingItem.dirty = true
                clothingItem.washing = false
            case "mazgajas":
                clothingItem.dirty = false
                clothingItem.washing = true
            default:
                break
            }
        }
        selectedClothingItemsIDs.removeAll()
        try? modelContext.save()
    }

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
                for item in favoriteClothingItems where selectedClothingItemsIDs.contains(item.id) {
                    modelContext.delete(item)
                }
                selectedClothingItemsIDs.removeAll()
                try? modelContext.save()
                isSelectionModeActive = false
            }
        }
    }
}



