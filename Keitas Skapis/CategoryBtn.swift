//
//  CategoryBtn.swift
//  Keitas Skapis
//
//  Created by Henrijs Obolevics on 14/12/2024.
//

import SwiftUI

struct CategoryButton: View {
    // MARK: - Properties
    
    let clothingCategory: ClothingCategory // The category to display in the button
    let isSelected: Bool // Indicates if the category is currently selected
    let onLongPress: (ClothingCategory) -> Void // Action to perform on long press gesture
    let toggleSelection: (ClothingCategory) -> Void // Action to toggle selection on tap gesture

    var body: some View {
        VStack {
            // Display the category's image if available, otherwise show a placeholder
            if let image = clothingCategory.displayedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.gray)
                    .opacity(0.5)
                    .padding(.top, 20)
                    .padding(.bottom, 10)
            }

            // Display the name of the clothing category
            Text(clothingCategory.name)
                .frame(width: 80, height: 30)
        }
        .frame(width: 90, height: 120) // Sets the overall size of the button
        .background(isSelected ? Color.blue.opacity(0.3) : Color(.white)) // Changes background based on selection
        .cornerRadius(8) // Rounds the corners of the button
        .contentShape(Rectangle()) // Makes the entire button area tappable
//        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.systemGray2), lineWidth: 1)) // Optional border
        .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2) // Adds a subtle shadow for depth
        .onTapGesture {
            toggleSelection(clothingCategory) // Toggles the selection state when tapped
        }
        .simultaneousGesture(
            LongPressGesture().onEnded { _ in
                onLongPress(clothingCategory) // Triggers the long press action
            }
        )
    }
}


