//
//  CategoryBtn.swift
//  Keitas Skapis
//
//  Created by Henrijs Obolevics on 14/12/2024.
//

import SwiftUI

struct CategoryButton: View {
    let kategorija: Kategorija
    let isSelected: Bool
    let onLongPress: (Kategorija) -> Void
    let toggleSelection: (Kategorija) -> Void

    var body: some View {
        VStack {
            if let image = kategorija.displayedImage {
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

            Text(kategorija.nosaukums)
                .frame(width: 80, height: 30)
        }
        .frame(width: 90, height: 120)
        .background(isSelected ? Color.blue.opacity(0.3) : Color(.systemGray6))
        .cornerRadius(8)
        .contentShape(Rectangle()) // Ensures the entire frame is tappable
        .onTapGesture {
            toggleSelection(kategorija)
        }
        .simultaneousGesture(
            LongPressGesture().onEnded { _ in
                onLongPress(kategorija)
            }
        )
    }
}


