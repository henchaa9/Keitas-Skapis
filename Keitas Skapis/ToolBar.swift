//
//  ToolBar.swift
//  Keitas Skapis
//
//  Created by Henrijs Obolevics on 14/12/2024.
//

import SwiftUI

struct ToolBar: View {
    @EnvironmentObject private var chosenManager: ChosenManager
    @State private var showChosenClothesSheet = false

    var body: some View {
        HStack {
            // 1) Izvēlētie (Cart) Button
            Button(action: {
                showChosenClothesSheet = true
            }) {
                VStack {
                    Image(systemName: "cart")
                        .font(.system(size: 24))
                        .foregroundStyle(.black)
                    Text("Izvēlētie")
                        .font(.footnote)
                        .foregroundStyle(.black)
                }
            }
            .frame(maxWidth: .infinity)
            // Show the "IzveletieView" sheet
            .sheet(isPresented: $showChosenClothesSheet) {
                IzveletieView()
                    .environmentObject(chosenManager)
            }
            
            // 2) Calendar Button
            NavigationLink(destination: CalendarView()) {
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
            
            // 3) Favorites Button
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

            // 4) Dirty Clothes Button
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

            // 5) Settings
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



