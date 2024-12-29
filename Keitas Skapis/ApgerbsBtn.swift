//
//  ApgerbsBtn.swift
//  Keitas Skapis
//
//  Created by Henrijs Obolevics on 14/12/2024.
//

import SwiftUI

struct ApgerbsButton: View {
    let apgerbs: Apgerbs
    let isSelected: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void

    @State private var image: UIImage?

    var body: some View {
        VStack {
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

            Text(apgerbs.nosaukums)
                .frame(width: 80, height: 30)
                .multilineTextAlignment(.center)
        }
        .frame(width: 90, height: 120)
        .background(isSelected ? Color.blue.opacity(0.3) : Color(.white))
        .cornerRadius(8)
        .contentShape(Rectangle()) // Ensures the entire frame is tappable
//        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.systemGray2), lineWidth: 1))
        .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture {
            onLongPress()
        }
        .onAppear {
            loadImage()
        }
    }

    private func loadImage() {
        apgerbs.loadImage { loadedImage in
            self.image = loadedImage
        }
    }
}



