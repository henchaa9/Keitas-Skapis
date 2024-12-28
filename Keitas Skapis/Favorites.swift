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

    @Query private var apgerbi: [Apgerbs]

    // Multi-selection
    @State private var selectedApgerbsIDs: Set<UUID> = []
    @State private var isSelectionModeActive = false

    // Action Sheet
    @State private var showActionSheet = false
    @State private var actionSheetType: ActionSheetType?

    // Detail
    @State private var showApgerbsDetail = false
    @State private var selectedApgerbs: Apgerbs?

    // Editing flow
    @State private var isEditing = false

    enum ActionSheetType {
        case apgerbsOptions
    }

    // Only show Apgerbs flagged as favorites
    private var favoriteApgerbi: [Apgerbs] {
        apgerbi.filter { $0.isFavorite }
    }

    var body: some View {
        NavigationStack {
            VStack {
                // Top bar
                HStack {
                    Text("Mīļākie")
                        .font(.title)
                        .bold()
                    
                    Spacer()
                    
                    // Pencil button if there's a selection
                    if !selectedApgerbsIDs.isEmpty {
                        Button(action: {
                            actionSheetType = .apgerbsOptions
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
                

                // Grid of favorite Apgerbs
                ScrollView {
                    ZStack {
                        // Detect tap on empty space to exit selection
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if isSelectionModeActive {
                                    isSelectionModeActive = false
                                    selectedApgerbsIDs.removeAll()
                                }
                            }

                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 90, maximum: 120))],
                            spacing: 10
                        ) {
                            ForEach(favoriteApgerbi, id: \.id) { apgerbs in
                                VStack {
                                    // Image
                                    AsyncImageView(apgerbs: apgerbs)
                                        .frame(width: 80, height: 80)
                                        .padding(.top, 5)
                                        .padding(.bottom, -10)

                                    // Title
                                    Text(apgerbs.nosaukums)
                                        .frame(width: 80, height: 30)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(width: 90, height: 120)
                                .background(
                                    selectedApgerbsIDs.contains(apgerbs.id)
                                        ? Color.blue.opacity(0.3)
                                        : Color(.systemGray6)
                                )
                                .cornerRadius(8)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if isSelectionModeActive {
                                        toggleApgerbsSelection(apgerbs)
                                    } else {
                                        // Show detail
                                        selectedApgerbs = apgerbs
                                        showApgerbsDetail = true
                                    }
                                }
                                .onLongPressGesture {
                                    // Enter selection mode on long press
                                    if !isSelectionModeActive {
                                        isSelectionModeActive = true
                                    }
                                    toggleApgerbsSelection(apgerbs)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            ToolBar()
            .sheet(isPresented: $showApgerbsDetail) {
                if let apgerbs = selectedApgerbs {
                    ApgerbsDetailView(
                        apgerbs: apgerbs,
                        onEdit: {
                            // Same pattern as NetirieApgerbiView
                            showApgerbsDetail = false
                            isEditing = true
                        },
                        onDelete: {
                            deleteSelectedApgerbs(apgerbs)
                            showApgerbsDetail = false
                        }
                    )
                } else {
                    Text("Nav izvēlēts apģērbs")
                }
            }
            .navigationDestination(isPresented: $isEditing) {
                if let apgerbs = selectedApgerbs {
                    PievienotApgerbuView(existingApgerbs: apgerbs)
                        .onDisappear {
                            isEditing = false
                        }
                }
            }
            .actionSheet(isPresented: $showActionSheet) {
                switch actionSheetType {
                case .apgerbsOptions:
                    return apgerbsActionSheet()
                case .none:
                    return ActionSheet(title: Text("Nav darbību"))
                }
            }
            .preferredColorScheme(.light)
        }
    }

    // MARK: - Action Sheet & Selection
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
        if selectedApgerbsIDs.isEmpty {
            isSelectionModeActive = false
        }
    }

    private func updateApgerbsStatus(to status: String) {
        for apgerbs in favoriteApgerbi where selectedApgerbsIDs.contains(apgerbs.id) {
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
        try? modelContext.save()
    }

    // Delete from the DB (same logic as in NetirieApgerbiView)
    private func deleteSelectedApgerbs(_ singleApgerbs: Apgerbs? = nil) {
        // Single item deletion
        if let single = singleApgerbs {
            selectedApgerbs = nil
            showApgerbsDetail = false
            DispatchQueue.main.async {
                modelContext.delete(single)
                try? modelContext.save()
            }
        }
        // Bulk deletion
        else if !selectedApgerbsIDs.isEmpty {
            DispatchQueue.main.async {
                for item in favoriteApgerbi where selectedApgerbsIDs.contains(item.id) {
                    modelContext.delete(item)
                }
                selectedApgerbsIDs.removeAll()
                try? modelContext.save()
            }
        }
    }
}


