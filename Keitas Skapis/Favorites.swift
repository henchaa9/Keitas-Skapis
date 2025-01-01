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
    // MARK: - Environment Variables

    @Environment(\.dismiss) var dismiss // Allows dismissing the view
    @Environment(\.modelContext) private var modelContext // Provides access to the data model context

    // MARK: - Data Query

    @Query private var clothingItems: [ClothingItem] // Fetches all clothing items from the model

    // MARK: - State Variables

    @State private var selectedClothingItemsIDs: Set<UUID> = [] // Tracks selected clothing items by ID
    @State private var isSelectionModeActive = false // Toggles selection mode for multi-select actions

    @State private var showActionSheet = false // Controls the display of the action sheet
    @State private var actionSheetType: ActionSheetType? // Determines the type of action sheet to display

    @State private var showClothingItemDetail = false // Toggles the display of the detail sheet
    @State private var selectedClothingItem: ClothingItem? // Tracks the currently selected clothing item for detail view

    @State private var isEditing = false // Toggles editing mode

    // MARK: - Enums

    /// Enum to specify the type of action sheet to display
    enum ActionSheetType {
        case clothingItemOptions
    }

    // MARK: - Computed Properties

    /// Filters clothing items to only those marked as favorites
    private var favoriteClothingItems: [ClothingItem] {
        clothingItems.filter { $0.isFavorite }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack {
                // Top Bar
                HStack {
                    Text("Mīļākie")
                        .font(.title)
                        .bold()
                        .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)

                    Spacer()

                    // Pencil button for actions when items are selected
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

                // Grid of favorite clothing items
                ScrollView {
                    ZStack {
                        // Tap detection to exit selection mode
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if isSelectionModeActive {
                                    isSelectionModeActive = false
                                    selectedClothingItemsIDs.removeAll()
                                }
                            }

                        // Adaptive grid for clothing items
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 90, maximum: 120))],
                            spacing: 10
                        ) {
                            ForEach(favoriteClothingItems, id: \.id) { item in
                                // Custom button for each clothing item
                                ApgerbsButton(
                                    clothingItem: item,
                                    isSelected: selectedClothingItemsIDs.contains(item.id),
                                    onTap: {
                                        if isSelectionModeActive {
                                            toggleClothingItemSelection(item) // Helper function
                                        } else {
                                            selectedClothingItem = item
                                            showClothingItemDetail = true
                                        }
                                    },
                                    onLongPress: {
                                        if !isSelectionModeActive {
                                            isSelectionModeActive = true
                                        }
                                        toggleClothingItemSelection(item) // Helper function
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Image("background_dmitriy_steinke").resizable().edgesIgnoringSafeArea(.all).opacity(0.3)) // Background image with slight opacity

            // MARK: - ToolBar
            // Toolbar at the bottom of the view
            ToolBar()
                .background(Color(.systemGray5))
                .padding(.top, -10)

            // Sheet for clothing item details
            .sheet(isPresented: $showClothingItemDetail) {
                if let clothingItem = selectedClothingItem {
                    // Detail view for selected clothing item
                    ApgerbsDetailView(
                        clothingItem: clothingItem,
                        onEdit: {
                            showClothingItemDetail = false
                            isEditing = true
                        },
                        onDelete: {
                            deleteSelectedClothingItem(clothingItem) // Helper function
                            showClothingItemDetail = false
                        }
                    )
                } else {
                    Text("Nav izvēlēts apģērbs") // Message when no item is selected
                }
            }

            // Navigation to editing view
            .navigationDestination(isPresented: $isEditing) {
                if let clothingItem = selectedClothingItem {
                    PievienotApgerbuView(existingClothingItem: clothingItem)
                        .onDisappear {
                            isEditing = false
                        }
                }
            }

            // Action sheet for managing clothing items
            .actionSheet(isPresented: $showActionSheet) {
                switch actionSheetType {
                case .clothingItemOptions:
                    return clothingItemActionSheet() // Helper function
                case .none:
                    return ActionSheet(title: Text("Nav darbību"))
                }
            }
            .preferredColorScheme(.light) // Light mode preference
        }
    }

    // MARK: - Action Sheet & Selection

    /// Creates the action sheet for managing clothing items.
    /// - Returns: An `ActionSheet` with options to update status or delete items.
    private func clothingItemActionSheet() -> ActionSheet {
        ActionSheet(
            title: Text("Pārvaldīt apģērbus"),
            buttons: [
                .default(Text("Mainīt uz Tīrs")) {
                    updateClothingItemStatus(to: "tirs") // Helper function
                },
                .default(Text("Mainīt uz Netīrs")) {
                    updateClothingItemStatus(to: "netirs") // Helper function
                },
                .default(Text("Mainīt uz Mazgājas")) {
                    updateClothingItemStatus(to: "mazgajas") // Helper function
                },
                .destructive(Text("Dzēst")) {
                    deleteSelectedClothingItem() // Helper function
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

    /// Updates the status of the selected clothing items.
    /// - Parameter status: The new status (`tirs`, `netirs`, or `mazgajas`).
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
        try? modelContext.save() // Saves the updates to the model
    }

    /// Deletes the selected clothing items or a single specified item.
    /// - Parameter singleClothingItem: A single clothing item to delete (optional).
    private func deleteSelectedClothingItem(_ singleClothingItem: ClothingItem? = nil) {
        if let single = singleClothingItem {
            // Deletes a single item
            selectedClothingItem = nil
            showClothingItemDetail = false
            DispatchQueue.main.async {
                modelContext.delete(single)
                try? modelContext.save()
                isSelectionModeActive = false
            }
        } else if !selectedClothingItemsIDs.isEmpty {
            // Deletes multiple selected items
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




