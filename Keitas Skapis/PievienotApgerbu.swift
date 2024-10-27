//
//  PievienotApgerbu.swift
//  Keitas Skapis
//
//  Created by Henrijs Obolevics on 10/10/2024.
//

import SwiftUI
import SwiftData

struct PievienotApgerbuView: View {
    
    @Query private var kategorijas: [Kategorija]
    @Query private var apgerbi: [Apgerbs]
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State var apgerbaNosaukums = ""
    @State var apgerbaPiezimes = ""
    
    
    @State private var isExpandedKategorijas = false
    @State private var isExpandedSezona = false

    @State var apgerbaKategorijas: Set<Kategorija> = []
    
    @State var izveletaKrasa: Color = .white
    @State var apgerbaKrasa: Krasa?
    
    @State var apgerbaStavoklis = 0
    @State var apgerbsGludinams = true
    @State var apgerbaIzmers = 0
    
    
//    @State var izveleVasara = false
//    @State var izveleRudens = false
//    @State var izveleZiema = false
//    @State var izvelePavasaris = false
    
    let sezonaIzvele = [Sezona.vasara, Sezona.rudens, Sezona.ziema, Sezona.pavasaris]
    @State var apgerbaSezona: Set<Sezona> = []
    
    
    @State var apgerbsPedejoreizVilkts = Date.now
    //attels
    
    
    var body: some View {
        VStack {
            HStack {
                Text("Pievienot Apģērbu").font(.title).bold()
                Spacer()
                Button(action: {dismiss()}) {
                    Image(systemName: "arrowshape.left.fill").font(.title).foregroundStyle(.black)
                }.navigationBarBackButtonHidden(true)
            }.padding()
            Spacer()
            ScrollView {
                VStack (alignment: .leading) {
                    
                    Button (action: pievienotFoto) {
                        ZStack {
                            Image(systemName: "rectangle.portrait.fill").resizable().frame(width: 60, height: 90).foregroundStyle(.gray).opacity(0.20)
                            Image(systemName: "camera").foregroundStyle(.black).font(.title2)
                        }
                    }
                    
                    TextField("Nosaukums", text: $apgerbaNosaukums).textFieldStyle(.roundedBorder).padding(.top, 20)
                    TextField("Piezīmes", text: $apgerbaPiezimes).textFieldStyle(.roundedBorder).padding(.top, 10)
                    
                    
                    VStack(alignment: .leading) {
                        Button(action: { isExpandedKategorijas.toggle() }) {
                            HStack {
                                Text("Kategorijas").foregroundStyle(.black)
                                Spacer()
                                Image(systemName: isExpandedKategorijas ? "chevron.up" : "chevron.down").foregroundStyle(.black)
                            }
                            .padding(10)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                        }
                        
                        if isExpandedKategorijas {
                            VStack {
                                ForEach(kategorijas, id: \.self) { kategorija in
                                    HStack {
                                        Text(kategorija.nosaukums)
                                        Spacer()
                                        if apgerbaKategorijas.contains(kategorija) {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                    .padding()
                                    .onTapGesture {
                                        if apgerbaKategorijas.contains(kategorija) {
                                            apgerbaKategorijas.remove(kategorija)
                                        } else {
                                            apgerbaKategorijas.insert(kategorija)
                                        }
                                    }
                                }
                            }
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(radius: 5)
                        }
                    }
                    .padding(.top, 10)
                    
                    ColorPicker("Krāsa", selection: Binding(
                        get: { izveletaKrasa },
                        set: { jaunaKrasa in
                            izveletaKrasa = jaunaKrasa
                            apgerbaKrasa = Krasa(color: jaunaKrasa)
                        })).padding(8)
                    
                    Picker("Izmērs", selection: $apgerbaIzmers) {
                        Text("XS").tag(0)
                        Text("S").tag(1)
                        Text("M").tag(3)
                        Text("L").tag(4)
                        Text("XL").tag(5)
                    }.pickerStyle(.segmented).padding(.top, 10)
                    
                    Picker("Stāvoklis", selection: $apgerbaStavoklis) {
                        Text("Tīrs").tag(0)
                        Text("Netīrs").tag(1)
                        Text("Mazgājas").tag(2)
                    }.pickerStyle(.segmented).padding(.top, 10)
                    
                    //                let columns = [GridItem(.flexible()), GridItem(.flexible())]
                    //                LazyVGrid(columns: columns, spacing: 15) {
                    //                     ForEach(Sezona.allCases, id: \.self) { sezona in
                    //                         Toggle(sezona.rawValue, isOn: Binding(
                    //                            get: { apgerbaSezona.contains(sezona) },
                    //                             set: { izvelets in
                    //                                 if izvelets {
                    //                                     apgerbaSezona.insert(sezona)
                    //                                 } else {
                    //                                     apgerbaSezona.remove(sezona)
                    //                                 }
                    //                             }
                    //                         ))
                    //                     }
                    //                 }
                    //                .padding(.top, 15).padding(.horizontal, 5)
                    
                    VStack(alignment: .leading) {
                        Button(action: { isExpandedSezona.toggle() }) {
                            HStack {
                                Text("Sezona").foregroundStyle(.black)
                                Spacer()
                                Image(systemName: isExpandedSezona ? "chevron.up" : "chevron.down").foregroundStyle(.black)
                            }
                            .padding(10)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                        }
                        
                        if isExpandedSezona {
                            VStack {
                                ForEach(sezonaIzvele, id: \.self) { sezona in
                                    HStack {
                                        Text(sezona.rawValue)
                                        Spacer()
                                        if apgerbaSezona.contains(sezona) {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                    .padding()
                                    .onTapGesture {
                                        if apgerbaSezona.contains(sezona) {
                                            apgerbaSezona.remove(sezona)
                                        } else {
                                            apgerbaSezona.insert(sezona)
                                        }
                                    }
                                }
                            }
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(radius: 5)
                        }
                    }
                    .padding(.top, 10)
                    
                    
                    DatePicker("Pēdējoreiz vilkts", selection: $apgerbsPedejoreizVilkts, displayedComponents: [.date]).padding(.top, 15).padding(.horizontal, 5)
                    
                    Toggle(isOn: $apgerbsGludinams) {
                        Text("Gludināms")
                    }.padding(.top, 15).padding(.horizontal, 5)
                    
                }
            }.padding()
        }.preferredColorScheme(.light)
            .background(Image("wardrobe_background")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .blur(radius: 5)
            .edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/))
                                    
    }
    
    func pievienotFoto () {
        print("foto pievienosana very cool")
    }
    
    func apstiprinat() {
        //modelContext.insert()
    }
    
    private func atjaunotSezonu(izveletaSezona: Sezona, izvele: Bool) {
        if izvele {
            apgerbaSezona.insert(izveletaSezona)
        } else {
            apgerbaSezona.remove(izveletaSezona)
        }
    }
}

#Preview {
    PievienotApgerbuView()
}
