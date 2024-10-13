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
