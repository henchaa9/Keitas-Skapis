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
    @Environment(\.modelContext) private var modelContext
    @Query private var apgerbi: [Apgerbs]
    
    @State private var showNetirie = true
    @State private var selectedApgerbsIDs: Set<UUID> = []
    @State private var showActionSheet = false
    @State private var actionSheetType: ActionSheetType?
    @State private var showApgerbsDetail = false
    @State private var selectedApgerbs: Apgerbs?

    enum ActionSheetType {
        case apgerbsOptions
    }

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
                // Top toggle between "Netīrie" and "Mazgājas"
                HStack(spacing: 20) {
                    Text("Netīrie")
                        .font(.headline)
                        .foregroundColor(showNetirie ? .blue : .primary)
                        .onTapGesture {
                            showNetirie = true
                        }
                    Text("Mazgājas")
                        .font(.headline)
                        .foregroundColor(!showNetirie ? .blue : .primary)
                        .onTapGesture {
                            showNetirie = false
                        }
                    
                    Spacer()
                    
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
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 90, maximum: 120))], spacing: 10) {
                        ForEach(filteredApgerbi, id: \.id) { apgerbs in
                            VStack {
                                AsyncImageView(apgerbs: apgerbs)
                                    .frame(width: 80, height: 80)
                                    .padding(.top, 5)
                                    .padding(.bottom, -10)
                                
                                Text(apgerbs.nosaukums)
                                    .frame(width: 80, height: 30)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(width: 90, height: 120)
                            .background(selectedApgerbsIDs.contains(apgerbs.id) ? Color.blue.opacity(0.3) : Color.gray.opacity(0.5))
                            .cornerRadius(8)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                // Single tap: show detail
                                selectedApgerbs = apgerbs
                                showApgerbsDetail = true
                            }
                            .simultaneousGesture(
                                LongPressGesture().onEnded { _ in
                                    // Long press: toggle selection
                                    toggleApgerbsSelection(apgerbs)
                                }
                            )
                            .sheet(isPresented: $showApgerbsDetail) {
                                if let apgerbs = selectedApgerbs {
                                    ApgerbsDetailView(
                                        apgerbs: apgerbs,
                                        onEdit: {
                                            // Handle editing if needed
                                            showApgerbsDetail = false
                                        },
                                        onDelete: {
                                            deleteSelectedApgerbs(apgerbs)
                                            showApgerbsDetail = false
                                        }
                                    )
                                }
                            }
                        }
                    }
                    .padding()
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
        try? modelContext.save()
    }

    private func deleteSelectedApgerbs(_ singleApgerbs: Apgerbs? = nil) {
        if let single = singleApgerbs {
            modelContext.delete(single)
            try? modelContext.save()
            selectedApgerbs = nil
        } else {
            for apgerbs in apgerbi where selectedApgerbsIDs.contains(apgerbs.id) {
                modelContext.delete(apgerbs)
            }
            selectedApgerbsIDs.removeAll()
            try? modelContext.save()
        }
    }
}


#Preview {
    NetirieApgerbiView()
}

