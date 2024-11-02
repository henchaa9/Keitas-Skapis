//
//  ContentView.swift
//  Keitas Skapis
//
//  Created by Henrijs Obolevics on 31/08/2024.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    
    //    @State private var showList: Bool = false // used for the picked items list
    //    @State private var showOutfit: Bool = false // used for the picked items list
    
    @Query private var kategorijas: [Kategorija]
    @Query private var apgerbi: [Apgerbs]
    @Environment(\.modelContext) private var modelContext
    
    
    var body: some View {
        NavigationStack {
            ScrollView (.horizontal) {
                HStack {
                    NavigationLink(destination: {
                        PievienotKategorijuView()
                    }, label: {
                        Image(systemName: "plus").frame(width: 90, height: 120).background(Color.gray.opacity(0.1)).foregroundStyle(.black).cornerRadius(8)
                    })
//                    ForEach (kategorijas) { kategorija in
//                        Text(kategorija.nosaukums).frame(width: 80, height: 110).background(.gray).padding(5)
                    
//                    }
                    ForEach(kategorijas) { kategorija in
                           VStack {
                               if let image = kategorija.image {
                                   // Display the image if it exists
                                   Image(uiImage: image)
                                       .resizable()
                                       .scaledToFit()
                                       .frame(width: 80, height: 80)
                                       .padding(.top, 5)
                                       .padding(.bottom, -10)
                               } else {
                                   // Show a placeholder if no image exists
                                   Image(systemName: "rectangle.portrait.fill")
                                       .resizable()
                                       .scaledToFit()
                                       .frame(width: 80, height: 80)
                                       .foregroundStyle(.gray)
                                       .opacity(0.5)
                                       .padding(.top, 5)
                                       .padding(.bottom, -10)
                               }
                               
                               // Display the category name below the image
                               Text(kategorija.nosaukums)
                                   .frame(width: 80, height: 30)
                                   .bold()

                           }
                           .frame(width: 90, height: 120)
                           .background(Color.gray.opacity(0.1))
                           .cornerRadius(8)
                       }
                }
            }.padding(.horizontal, 10)
            NavigationLink(destination: {
                PievienotApgerbuView()
            }, label: {
                Text("Pievienot apgerbu")
            })
        }.preferredColorScheme(.light)
        
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
