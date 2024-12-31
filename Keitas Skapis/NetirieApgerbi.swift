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

    // Filter the Apgerbs to show either netīrs or mazgājas
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
                // Top bar with toggles between "Netīrie" and "Mazgājas"
                HStack(spacing: 20) {
                    Text("Netīrie")
                        .font(.title).bold().shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                        .foregroundColor(showDirty ? .blue : .primary)
                        .onTapGesture {
                            showDirty = true
                        }

                    Text("Mazgājas")
                        .font(.title).bold().shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                        .foregroundColor(!showDirty ? .blue : .primary)
                        .onTapGesture {
                            showDirty = false
                        }
                        .navigationBarBackButtonHidden(true)
                    
                    Spacer()
                    
                    // Pencil button appears only if some Apgerbs are selected
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

                // Grid of Apgerbi using ApgerbsButton
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

            // Detail Sheet
            .sheet(isPresented: $showClothingItemDetail) {
                if let item = selectedClothingItem {
                    ApgerbsDetailView(
                        clothingItem: item,
                        onEdit: {
                            showClothingItemDetail = false
                            isEditing = true
                        },
                        onDelete: {
                            deleteSelectedClothingItem(item)
                            showClothingItemDetail = false
                        }
                    )
                } else {
                    Text("No Apgerbs Selected")
                }
            }

            // Edit Screen Navigation
            .navigationDestination(isPresented: $isEditing) {
                if let item = selectedClothingItem {
                    PievienotApgerbuView(existingClothingItem: item)
                        .onDisappear {
                            isEditing = false
                        }
                }
            }

            // Action Sheet
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

