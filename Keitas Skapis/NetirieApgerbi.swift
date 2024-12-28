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

    @Query private var apgerbi: [Apgerbs]

    @State private var showNetirie = true
    @State private var selectedApgerbsIDs: Set<UUID> = []
    @State private var showActionSheet = false
    @State private var actionSheetType: ActionSheetType?
    @State private var showApgerbsDetail = false
    @State private var selectedApgerbs: Apgerbs?
    @State private var isSelectionModeActive = false

    // 1) Add this state to control navigation to the edit screen:
    @State private var isEditing = false

    enum ActionSheetType {
        case apgerbsOptions
    }

    // Filter the Apgerbs to show either netīrs or mazgājas
    var filteredApgerbi: [Apgerbs] {
        apgerbi.filter { item in
            if showNetirie {
                return item.netirs == true
            } else {
                return item.mazgajas == true
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                // Top bar with toggles between "Netīrie" and "Mazgājas"
                HStack(spacing: 20) {
                    Text("Netīrie")
                        .font(.title)
                        .foregroundColor(showNetirie ? .blue : .primary)
                        .bold()
                        .onTapGesture {
                            showNetirie = true
                        }

                    Text("Mazgājas")
                        .font(.title)
                        .foregroundColor(!showNetirie ? .blue : .primary)
                        .bold()
                        .onTapGesture {
                            showNetirie = false
                        }
                        .navigationBarBackButtonHidden(true)
                    
                    Spacer()
                    
                    // Pencil button appears only if some Apgerbs are selected
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
                .padding()

                // Grid of Apgerbi
                ScrollView {
                    ZStack {
                        // Tap on empty space exits selection mode
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
                            ForEach(filteredApgerbi, id: \.id) { apgerbs in
                                VStack {
                                    // Show the image
                                    AsyncImageView(apgerbs: apgerbs)
                                        .frame(width: 80, height: 80)
                                        .padding(.top, 5)
                                        .padding(.bottom, -10)
                                    
                                    // Show the title
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
                                    // If in selection mode, toggle selection
                                    if isSelectionModeActive {
                                        toggleApgerbsSelection(apgerbs)
                                    } else {
                                        // If not in selection mode, show detail
                                        selectedApgerbs = apgerbs
                                        showApgerbsDetail = true
                                    }
                                }
                                .onLongPressGesture {
                                    // Long press enters selection mode if not active, then toggles selection
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
            
            // Present the Detail Sheet
            .sheet(isPresented: $showApgerbsDetail) {
                if let apgerbs = selectedApgerbs {
                    ApgerbsDetailView(
                        apgerbs: apgerbs,
                        onEdit: {
                            // 2) When “Rediģet” is pressed:
                            // - Close the detail sheet
                            // - Trigger the `navigationDestination` below
                            showApgerbsDetail = false
                            isEditing = true
                        },
                        onDelete: {
                            deleteSelectedApgerbs(apgerbs)
                            showApgerbsDetail = false
                        }
                    )
                } else {
                    Text("No Apgerbs Selected")
                }
            }

            // 3) Here’s where we push the PievienotApgerbuView
            .navigationDestination(isPresented: $isEditing) {
                if let apgerbs = selectedApgerbs {
                    PievienotApgerbuView(existingApgerbs: apgerbs)
                        .onDisappear {
                            // Optional cleanup
                            isEditing = false
                            // selectedApgerbs = nil (if desired)
                        }
                }
            }

            // Action Sheet for bulk updates or deletion
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
        try? modelContext.save()
    }

    private func deleteSelectedApgerbs(_ singleApgerbs: Apgerbs? = nil) {
        if let single = singleApgerbs {
            selectedApgerbs = nil
            showApgerbsDetail = false

            DispatchQueue.main.async {
                modelContext.delete(single)
                try? modelContext.save()
            }
        }
        else if !selectedApgerbsIDs.isEmpty {
            DispatchQueue.main.async {
                for item in apgerbi where selectedApgerbsIDs.contains(item.id) {
                    modelContext.delete(item)
                }
                selectedApgerbsIDs.removeAll()
                try? modelContext.save()
            }
        }
    }

}



#Preview {
    NetirieApgerbiView()
}

