//
//  ImageLoader.swift
//  Keitas Skapis
//
//  Created by Henrijs Obolevics on 01/01/2025.
//


import SwiftUI
import Combine
import UIKit

class ImageLoader: ObservableObject {
    @Published var image: UIImage?

    private let clothingItem: ClothingItem

    init(clothingItem: ClothingItem) {
        self.clothingItem = clothingItem
        self.loadImage()
    }

    func loadImage() {
        clothingItem.loadImage { [weak self] loadedImage in
            self?.image = loadedImage
        }
    }
}

struct AsyncImageView: View {
    @ObservedObject private var loader: ImageLoader

    init(clothingItem: ClothingItem) {
        self.loader = ImageLoader(clothingItem: clothingItem)
    }

    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.gray)
            }
        }
    }
}
