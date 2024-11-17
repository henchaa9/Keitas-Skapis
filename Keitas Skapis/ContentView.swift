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
    
    // State variables for managing actions
    @State private var selectedKategorija: Kategorija?
    @State private var selectedApgerbs: Apgerbs?
    @State private var showActionSheet = false
    @State private var isEditingKategorija = false
    @State private var isEditingApgerbs = false
    @State private var showDeleteSheet = false
    @State private var showDeleteConfirmation = false
    @State private var newKategorijaName = "" // For adding a new kategorija
    @State private var showAddConfirmation = false
    @State private var targetKategorija: Kategorija? // The selected target kategorija
    
    private let adaptiveColumn = [
        GridItem(.adaptive(minimum: 90, maximum: 120))
    ]
    
    var body: some View {
        NavigationStack {
            VStack {
                // Categories Section
                ScrollView(.horizontal) {
                    HStack {
                        // Add new category button
                        NavigationLink(destination: PievienotKategorijuView()) {
                            Image(systemName: "plus")
                                .frame(width: 90, height: 120)
                                .background(Color.gray.opacity(0.1))
                                .foregroundStyle(.black)
                                .cornerRadius(8)
                        }
                        
                        // Display existing categories
                        ForEach(kategorijas) { kategorija in
                            VStack {
                                if let image = kategorija.image {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 80, height: 80)
                                        .padding(.top, 5)
                                        .padding(.bottom, -10)
                                } else {
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
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .onLongPressGesture {
                                selectedApgerbs = nil // Clear previous selection
                                selectedKategorija = kategorija
                                showActionSheet = true
                            }
                        }
                    }
                }
                .padding(.horizontal, 10)
                
                // Add clothing item button
                NavigationLink(destination: PievienotApgerbuView()) {
                    Text("Pievienot apgerbu")
                }
                .padding(.bottom, 10)
                
                // Clothing Items Section
                ScrollView {
                    LazyVGrid(columns: adaptiveColumn, spacing: 10) {
                        ForEach(apgerbi, id: \.self) { apgerbs in
                            VStack {
                                if let image = apgerbs.image {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 80, height: 80)
                                        .padding(.top, 5)
                                        .padding(.bottom, -10)
                                } else {
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
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .onLongPressGesture {
                                selectedKategorija = nil // Clear previous selection
                                selectedApgerbs = apgerbs
                                showActionSheet = true
                            }
                        }
                    }
                }
                .padding()
            }
            .actionSheet(isPresented: $showActionSheet) {
                ActionSheet(
                    title: Text("Choose an action"),
                    buttons: [
                        .default(Text("Edit")) {
                            if selectedKategorija != nil {
                                isEditingKategorija = true
                            } else if selectedApgerbs != nil {
                                isEditingApgerbs = true
                            }
                        },
                        .destructive(Text("Delete")) {
                            deleteSelectedItem()
                        },
                        .cancel()
                    ]
                )
            }
            .sheet(isPresented: $showDeleteSheet) {
                VStack {
                    Text("Kategorija \(selectedKategorija?.nosaukums ?? "") contains \(selectedKategorija?.apgerbi.count ?? 0) apgerbs.")
                        .font(.headline)
                        .padding()
                    
                    // Horizontal List of Categories
                    ScrollView(.horizontal) {
                        HStack {
                            // Add button for creating a new category
                            NavigationLink(destination: PievienotKategorijuView(apgerbiToAdd: selectedKategorija?.apgerbi ?? [])) {
                                Image(systemName: "plus")
                                    .frame(width: 90, height: 120)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            
                            // List of other categories
                            ForEach(kategorijas.filter { $0.id != selectedKategorija?.id }) { kategorija in
                                VStack {
                                    if let image = kategorija.image {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 80, height: 80)
                                    }
                                    Text(kategorija.nosaukums)
                                        .frame(width: 80)
                                }
                                .frame(width: 90, height: 120)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                                .onTapGesture {
                                    targetKategorija = kategorija
                                    showAddConfirmation = true
                                }
                            }
                        }
                        .padding()
                    }
                    
                    // Delete All Button
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        Text("Delete All Apgerbs and Kategorija")
                            .foregroundColor(.red)
                    }
                    .padding()
                    .confirmationDialog(
                        "Are you sure you want to delete all Apgerbs and the Kategorija?",
                        isPresented: $showDeleteConfirmation,
                        actions: {
                            Button("Delete", role: .destructive) {
                                deleteAllInKategorija()
                            }
                            Button("Cancel", role: .cancel) {}
                        }
                    )
                }
                .padding()
                .confirmationDialog(
                    "Add Apgerbs to \(targetKategorija?.nosaukums ?? "")?",
                    isPresented: $showAddConfirmation,
                    titleVisibility: .visible
                ) {
                    if let currentKategorija = selectedKategorija, let targetKategorija = targetKategorija {
                        Button("Move \(currentKategorija.apgerbi.count) Apgerbs") {
                            moveApgerbi(to: targetKategorija)
                            showAddConfirmation = false // Reset the state
                        }
                    }
                    Button("Cancel", role: .cancel) {
                        showAddConfirmation = false // Reset the state on cancel
                    }
                }
            }
            .preferredColorScheme(.light)
        }
    }
    
    // MARK: - Helper Functions
    
    func deleteAllInKategorija() {
        // Delete all associated Apgerbs and the selected Kategorija
        if let kategorija = selectedKategorija {
            for apgerbs in kategorija.apgerbi {
                modelContext.delete(apgerbs)
            }
            modelContext.delete(kategorija)
            selectedKategorija = nil
        }
    }
    
    func moveApgerbi(to newKategorija: Kategorija) {
        // Move Apgerbs from the current Kategorija to a new Kategorija
        if let currentKategorija = selectedKategorija {
            for apgerbs in currentKategorija.apgerbi {
                newKategorija.apgerbi.append(apgerbs)
            }
            modelContext.delete(currentKategorija) // Delete the old Kategorija
            selectedKategorija = nil
        }
    }
    
    func deleteSelectedItem() {
        // Delete the selected Kategorija or Apgerbs
        if let kategorija = selectedKategorija {
            if kategorija.apgerbi.isEmpty {
                modelContext.delete(kategorija)
                selectedKategorija = nil
            } else {
                showDeleteSheet = true
            }
        } else if let apgerbs = selectedApgerbs {
            modelContext.delete(apgerbs)
            selectedApgerbs = nil
        }
    }
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
