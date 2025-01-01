//
//  ApgerbsBtn.swift
//  Keitas Skapis
//
//  Created by Henrijs Obolevics on 14/12/2024.
//

import SwiftUI

struct ApgerbsButton: View {
    // MARK: - Properties
    
    let clothingItem: ClothingItem // The clothing item to display
    let isSelected: Bool // Indicates if the clothing item is currently selected
    let onTap: () -> Void // Action to perform on tap gesture
    let onLongPress: () -> Void // Action to perform on long press gesture

    @State private var image: UIImage? // Holds the loaded image for the clothing item

    var body: some View {
        VStack {
            // Display the clothing item's image if available, otherwise show a placeholder
            if let image = image {
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
                    .padding(.top, 15)
                    .padding(.bottom, 10)
            }

            // Display the name of the clothing item
            Text(clothingItem.name)
                .frame(width: 80, height: 30)
                .multilineTextAlignment(.center)
        }
        .frame(width: 90, height: 120) // Sets the overall size of the button
        .background(isSelected ? Color.blue.opacity(0.3) : Color(.white)) // Changes background based on selection
        .cornerRadius(8) // Rounds the corners of the button
        .contentShape(Rectangle()) // Ensures the entire frame is tappable
//        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.systemGray2), lineWidth: 1)) // Optional border
        .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2) // Adds a subtle shadow for depth
        .onTapGesture {
            onTap() // Executes the tap action when the button is tapped
        }
        .onLongPressGesture {
            onLongPress() // Executes the long press action when the button is long-pressed
        }
        .onAppear {
            loadImage() // Loads the image when the view appears
        }
    }

    // MARK: - Helper Methods
    
    /// Loads the image for the clothing item asynchronously
    private func loadImage() {
        clothingItem.loadImage { loadedImage in
            self.image = loadedImage // Sets the loaded image to display
        }
    }
}




