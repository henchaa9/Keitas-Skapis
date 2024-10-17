//
//  PievienotApgerbu.swift
//  Keitas Skapis
//
//  Created by Henrijs Obolevics on 10/10/2024.
//

import SwiftUI
import SwiftData

struct PievienotApgerbuView: View {
    
    @Query var kategorijas: [Kategorija]
    @Query var apgerbi: [Apgerbs]
    
    @Environment(\.modelContext) var modelContext
    
    @State var apgerbaNosaukums = ""
    @State var apgerbaPiezimes = ""
    
    @State var izveletaKrasa: Color = .white
    @State var apgerbaKrasa: Krasa?
    
    @State var apgerbaStavoklis = 0
    @State var apgerbsGludinams = true
    @State var apgerbaIzmers = 0
    @State var apgerbaSezona = []
    @State var apgerbsPedejoreizVilkts = Date.now
    //attels
    
    var body: some View {
        HStack {
            Text("Pievienot Apģērbu").font(.title).bold()
            Spacer()
            Button(action: atpakal) {
                Image(systemName: "arrowshape.left.fill").font(.title).foregroundStyle(.black)
            }
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
                
                Toggle(isOn: $apgerbsGludinams) {
                    Text("Gludināms")
                }.padding(.top, 15).padding(.horizontal, 5)
                
                
                DatePicker("Pēdējoreiz vilkts", selection: $apgerbsPedejoreizVilkts, displayedComponents: [.date]).padding(.top, 15).padding(.horizontal, 5)
            }
        }.padding()
    }
    
    func atpakal () {
        print("eju atpakal")
    }
    
    func pievienotFoto () {
        print("foto pievienosana very cool")
    }
    
    func apstiprinat() {
        //modelContext.insert()
    }
}

#Preview {
    PievienotApgerbuView()
}
