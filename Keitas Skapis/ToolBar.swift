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
            // 1) Home Navigation Link
            NavigationLink(destination: ContentView()) {
                VStack {
                    Image(systemName: "house") // Home icon
                        .font(.system(size: 24))
                        .foregroundStyle(.black)
                    Text("Sākums") // "Home" label
                        .font(.footnote)
                        .foregroundStyle(.black)
                }
            }
            .frame(maxWidth: .infinity)

            // 2) Izvēlētie (Selected Clothes) Button
            Button(action: {
                showChosenClothesSheet = true // Show the selected clothes sheet
            }) {
                VStack {
                    Image(systemName: "cart") // Cart icon
                        .font(.system(size: 24))
                        .foregroundStyle(.black)
                    Text("Izvēlētie") // "Selected" label
                        .font(.footnote)
                        .foregroundStyle(.black)
                }
            }
            .frame(maxWidth: .infinity)
            // Presents the IzveletieView sheet when the button is tapped
            .sheet(isPresented: $showChosenClothesSheet) {
                IzveletieView()
                    .environmentObject(chosenManager) // Passes the chosenManager to the sheet
            }

            // 3) Favorites Navigation Link
            NavigationLink(destination: FavoritesView()) {
                VStack {
                    Image(systemName: "heart") // Heart icon
                        .font(.system(size: 24))
                        .foregroundStyle(.black)
                    Text("Mīļākie") // "Favorites" label
                        .font(.footnote)
                        .foregroundStyle(.black)
                }
            }
            .frame(maxWidth: .infinity)

            // 4) Calendar Navigation Link
            NavigationLink(destination: CalendarView()) {
                VStack {
                    Image(systemName: "calendar") // Calendar icon
                        .font(.system(size: 24))
                        .foregroundStyle(.black)
                    Text("Kalendārs") // "Calendar" label
                        .font(.footnote)
                        .foregroundStyle(.black)
                }
            }
            .frame(maxWidth: .infinity)

            // 5) Dirty Clothes Navigation Link
            NavigationLink(destination: NetirieApgerbiView()) {
                VStack {
                    Image(systemName: "washer") // Washer icon
                        .font(.system(size: 24))
                        .foregroundStyle(.black)
                    Text("Netīrie") // "Dirty" label
                        .font(.footnote)
                        .foregroundStyle(.black)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.systemGray6)) // Light gray background
        .cornerRadius(12) // Rounded corners
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.black), lineWidth: 1)) // Black border
        .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2) // Shadow effect
        .padding(.horizontal, 5)
    }
}




