//
//  PievienotKategoriju.swift
//  Keitas Skapis
//
//  Created by Henrijs Obolevics on 06/10/2024.
//

import SwiftUI
import SwiftData

struct PievienotKategorijuView: View {
    
    @Query var kategorijas: [Kategorija]
    @Environment(\.modelContext) var modelContext
    @State var kategorijasNosaukums = ""
    
    var body: some View {
        HStack {
            Text("Pievienot Kategoriju").font(.title).bold()
            Spacer()
            Button(action: atpakal) {
                Image(systemName: "arrowshape.left.fill").font(.title).foregroundStyle(.black)
            }
        }.padding()
        Spacer()
        VStack (alignment: .leading) {
            Button (action: pievienotFoto) {
                ZStack {
                    Image(systemName: "rectangle.portrait.fill").resizable().frame(width: 60, height: 90).foregroundStyle(.gray).opacity(0.50)
                    Image(systemName: "camera").foregroundStyle(.black).font(.title2)
                }
            }
            Text("Foto").font(.title3)
            TextField("", text: $kategorijasNosaukums).textFieldStyle(.roundedBorder).padding(.top, 30)
            Text("Nosaukums").font(.title3).padding(.bottom, 150)
        }.padding()
        Spacer()
        HStack {
            Button (action: apstiprinat) {
                Text("Apstiprinat")
            }
            Spacer()
        }.padding()
    }
    
    func atpakal () {
        print("eju atpakal")
    }
    
    func pievienotFoto () {
        print("foto pievienosana very cool")
    }
    
    func apstiprinat() {
        print("apstiprinu yeehaw")
    }
}

#Preview {
    PievienotKategorijuView()
}
