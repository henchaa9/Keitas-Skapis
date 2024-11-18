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

    @State private var selectedKategorija: Kategorija?
    @State private var selectedApgerbs: Apgerbs?
    @State private var showActionSheet = false
    @State private var actionSheetType: ActionSheetType?
    @State private var isEditing = false

    enum ActionSheetType {
        case kategorija, apgerbs
    }

    var body: some View {
        NavigationStack {
            VStack {
                // Categories Section
                ScrollView(.horizontal) {
                    HStack {
                        NavigationLink(destination: PievienotKategorijuView()) {
                            Image(systemName: "plus")
                                .frame(width: 90, height: 120)
                                .background(Color.gray.opacity(0.1))
                                .foregroundStyle(.black)
                                .cornerRadius(8)
                        }

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
                            .contentShape(Rectangle()) // Ensures the whole area is tappable
                            .onLongPressGesture {
                                print("Long press on Kategorija: \(kategorija.nosaukums)")
                                selectedKategorija = kategorija
                                selectedApgerbs = nil
                                actionSheetType = .kategorija
                                showActionSheet = true
                            }
                        }
                    }
                }
                .padding(.horizontal, 10)

                // Add Clothing Button
                NavigationLink(destination: PievienotApgerbuView()) {
                    Text("Pievienot apgerbu")
                }
                .padding(.bottom, 10)

                // Clothing Items Section
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 90, maximum: 120))], spacing: 10) {
                        ForEach(apgerbi, id: \.id) { apgerbs in
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
                            .contentShape(Rectangle()) // Ensures the whole area is tappable
                            .onLongPressGesture {
                                print("Long press on Apgerbs: \(apgerbs.nosaukums)")
                                selectedApgerbs = apgerbs
                                selectedKategorija = nil
                                actionSheetType = .apgerbs
                                showActionSheet = true
                            }
                        }
                    }
                }
                .padding()
            }
            .actionSheet(isPresented: $showActionSheet) {
                switch actionSheetType {
                case .kategorija:
                    return kategorijaActionSheet()
                case .apgerbs:
                    return apgerbsActionSheet()
                case .none:
                    return ActionSheet(title: Text("Error"))
                }
            }
            .navigationDestination(isPresented: $isEditing) {
                if let kategorija = selectedKategorija {
                    PievienotKategorijuView(existingKategorija: kategorija)
                } else if let apgerbs = selectedApgerbs {
                    PievienotApgerbuView(existingApgerbs: apgerbs)
                }
            }
        }
        .preferredColorScheme(.light)
    }

    private func kategorijaActionSheet() -> ActionSheet {
        ActionSheet(
            title: Text("Manage \(selectedKategorija?.nosaukums ?? "")"),
            message: Text("This category contains \(selectedKategorija?.apgerbi.count ?? 0) items."),
            buttons: [
                .default(Text("Edit")) {
                    isEditing = true
                },
                .default(Text("Delete Category Only")) {
                    removeKategorijaOnly()
                },
                .destructive(Text("Delete Category and Items")) {
                    deleteKategorijaAndItems()
                },
                .cancel()
            ]
        )
    }

    private func apgerbsActionSheet() -> ActionSheet {
        ActionSheet(
            title: Text("Manage \(selectedApgerbs?.nosaukums ?? "")"),
            buttons: [
                .default(Text("Edit")) {
                    isEditing = true
                },
                .destructive(Text("Delete")) {
                    deleteSelectedApgerbs()
                },
                .cancel()
            ]
        )
    }

    private func removeKategorijaOnly() {
        if let kategorija = selectedKategorija {
            for apgerbs in kategorija.apgerbi {
                apgerbs.kategorijas.removeAll { $0 == kategorija }
            }
            modelContext.delete(kategorija)
            selectedKategorija = nil
        }
    }

    private func deleteKategorijaAndItems() {
        if let kategorija = selectedKategorija {
            for apgerbs in kategorija.apgerbi {
                modelContext.delete(apgerbs)
            }
            modelContext.delete(kategorija)
            selectedKategorija = nil
        }
    }

    private func deleteSelectedApgerbs() {
        if let apgerbs = selectedApgerbs {
            modelContext.delete(apgerbs)
            selectedApgerbs = nil
        }
    }
}

    
#Preview {
    ContentView()
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
