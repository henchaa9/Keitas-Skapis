//
//  ToolBar.swift
//  Keitas Skapis
//
//  Created by Henrijs Obolevics on 14/12/2024.
//

import SwiftUI

struct ToolBar: View {
    @State private var showChosenClothesSheet = false

    var body: some View {
        HStack {
            // Chosen Clothes Button
            Button(action: {
                showChosenClothesSheet.toggle()
            }) {
                VStack {
                    Image(systemName: "cart") // Basket Icon
                        .font(.system(size: 24))
                        .foregroundStyle(.black)
                    Text("Izvēlētie")
                        .font(.footnote)
                        .foregroundStyle(.black)
                }
            }
            .frame(maxWidth: .infinity)
            .sheet(isPresented: $showChosenClothesSheet) {
                Text("Chosen Clothes Sheet Coming Soon")
            }
            

            // Calendar Button
            NavigationLink(destination: Text("Calendar View Coming Soon")) {
                VStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 24))
                        .foregroundStyle(.black)
                    Text("Kalendārs")
                        .font(.footnote)
                        .foregroundStyle(.black)
                }
            }
            .frame(maxWidth: .infinity)
            
            // Favorites Button
            NavigationLink(destination: FavoritesView()) {
                VStack {
                    Image(systemName: "heart")
                        .font(.system(size: 24))
                        .foregroundStyle(.black)
                    Text("Mīļākie")
                        .font(.footnote)
                        .foregroundStyle(.black)
                }
            }
            .frame(maxWidth: .infinity)

            // Dirty Clothes Button
            NavigationLink(destination: NetirieApgerbiView()) {
                VStack {
                    Image(systemName: "washer")
                        .font(.system(size: 24))
                        .foregroundStyle(.black)
                    Text("Netīrie")
                        .font(.footnote)
                        .foregroundStyle(.black)
                }
            }
            .frame(maxWidth: .infinity)

            // Settings/Help Button
            NavigationLink(destination: Text("Settings/Help View Coming Soon")) {
                VStack {
                    Image(systemName: "gear")
                        .font(.system(size: 24))
                        .foregroundStyle(.black)
                    Text("Iestatījumi")
                        .font(.footnote)
                        .foregroundStyle(.black)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
    }
}

struct ToolBar_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            VStack {
                Spacer()
                ToolBar()
            }
        }
    }
}


