
import SwiftUI
import Combine
import UIKit


// attēla tips
enum ImageType {
    case thumbnail
    case original
}

// Ielādē apģērba attēlu un padod to skatiem
class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    
    private let clothingItem: ClothingItem
    private let imageType: ImageType
    
    init(clothingItem: ClothingItem, imageType: ImageType = .original) {
        self.clothingItem = clothingItem
        self.imageType = imageType
        self.loadImage()
    }
    
    func loadImage() {
        // Padod flag, lai zinātu vai ielādēt thumbnail
        clothingItem.loadImage(useThumbnail: (imageType == .thumbnail)) { [weak self] loadedImage in
            guard let self = self else { return }
            self.image = loadedImage
        }
    }
}


// Asinhroni ielādē attēlu, izmantojot ImageLoader iegūst to
struct AsyncImageView: View {
    @ObservedObject private var loader: ImageLoader
    
    init(clothingItem: ClothingItem, imageType: ImageType = .original) {
        // Padod attēlu ImageLoader
        self.loader = ImageLoader(clothingItem: clothingItem, imageType: imageType)
    }
    
    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                // fallback attēls
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.gray)
            }
        }
    }
}


