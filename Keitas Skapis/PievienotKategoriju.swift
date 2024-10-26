//
//  PievienotKategoriju.swift
//  Keitas Skapis
//
//  Created by Henrijs Obolevics on 06/10/2024.
//

import SwiftUI
import SwiftData

struct PievienotKategorijuView: View {
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    @State var kategorijasNosaukums = ""
    
    var body: some View {
        HStack {
            Text("Pievienot Kategoriju").font(.title).bold()
            Spacer()
            Button(action: {dismiss()}) {
                Image(systemName: "arrowshape.left.fill").font(.title).foregroundStyle(.black)
            }.navigationBarBackButtonHidden(true)
        }.padding()
        VStack (alignment: .leading) {
            Button (action: pievienotFoto) {
                ZStack {
                    Image(systemName: "rectangle.portrait.fill").resizable().frame(width: 60, height: 90).foregroundStyle(.gray).opacity(0.50)
                    Image(systemName: "camera").foregroundStyle(.black).font(.title2)
                }
            }
            TextField("Nosaukums", text: $kategorijasNosaukums).textFieldStyle(.roundedBorder).padding(.top, 20)
        }.padding(.top, 50).padding(.horizontal, 20)
        Spacer()
        HStack {
            Button (action: apstiprinat) {
                Text("Apstiprinat")
            }
            Spacer()
        }.padding()
    }
    
    func pievienotFoto () {
        print("foto pievienosana very cool")
    }
    
    func apstiprinat() {
        let jaunaKategorija = Kategorija(nosaukums: kategorijasNosaukums)
        modelContext.insert(jaunaKategorija)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    PievienotKategorijuView()
}
