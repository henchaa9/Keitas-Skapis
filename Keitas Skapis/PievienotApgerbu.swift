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
    @State var apgerbaKrasa = ""
    @State var apgerbaStavoklis = 0
    @State var apgerbaGludinams = true
    @State var apgerbaIzmers = ""
    @State var apgerbaSezona = []
    @State var apgerbaPedejoreizVilkts = Date.now
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
                        Image(systemName: "rectangle.portrait.fill").resizable().frame(width: 60, height: 90).foregroundStyle(.gray).opacity(0.50)
                        Image(systemName: "camera").foregroundStyle(.black).font(.title2)
                    }
                }
                Text("Foto").font(.title3)
                TextField("", text: $apgerbaNosaukums).textFieldStyle(.roundedBorder).padding(.top, 15)
                Text("Nosaukums").font(.title3)
                TextField("", text: $apgerbaPiezimes).textFieldStyle(.roundedBorder).padding(.top, 15)
                Text("Piezīmes").font(.title3)
                TextField("", text: $apgerbaKrasa).textFieldStyle(.roundedBorder).padding(.top, 15)
                Text("Krāsa").font(.title3)
                //stavoklis ir ta slidinama izvele no vidika
                //gludinams ir toggle
                TextField("", text: $apgerbaIzmers).textFieldStyle(.roundedBorder).padding(.top, 15)
                Text("Nosaukums").font(.title3)
                //sezona ir checkboxes, par katru pievieno nosaukumu sarakstam
                //pedejoreiz vilkts ir kkads date picker
                HStack {
                    Button (action: apstiprinat) {
                        Text("Apstiprināt")
                    }
                }.padding(.top, 15)
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
