
import SwiftUI
import Combine
import UIKit

// MARK: - ImageLoader

// Objekts, kas atbild par asinhronu attēla ielādi kādam izvēlētam apģērbam
// Atgūst apģērba attēlu, un padod to skatiem, kuriem tas vajadzīgs
class ImageLoader: ObservableObject {
    // Ielādētais attēls
    @Published var image: UIImage?
    
    // Apģērbs, kuram piesaistīts attēls
    private let clothingItem: ClothingItem
    
    // Inicializē ImageLoader un uzsāk attēla ielādi
    /// - Parameter clothingItem: Apģērbs, kuram piesaistīts attēls
    init(clothingItem: ClothingItem) {
        self.clothingItem = clothingItem
        self.loadImage()
    }
    
    // Uzsāk attēla ielādi apģērbam
    /// Izsaucot `loadImage` metodi, tiek atjaunināta `image` vērtība apģērbam.
    func loadImage() {
        clothingItem.loadImage { [weak self] loadedImage in
            // Pārliecināts par referenci uz sevi, lai novērstu atmiņas noplūdi
            guard let self = self else { return }
            // Atjaunina 'image' vērtību
            self.image = loadedImage
        }
    }
}

// MARK: - AsyncImageView

// Skats, kas asinhroni attēlo apģērba attēlu
// Ja attēls ir pievienots un ielādēts, parāda to, ja nē, parāda noklusējuma attēlu
struct AsyncImageView: View {
    // Vēro ImageLoader, lai iegūtu ielādēto attēlu
    @ObservedObject private var loader: ImageLoader
    
    // Inicializē asinhrono skatu
    /// - Parameter clothingItem: Apģērbs, kuram jāparāda attēlu
    init(clothingItem: ClothingItem) {
        self.loader = ImageLoader(clothingItem: clothingItem)
    }
    
    var body: some View {
        Group {
            if let image = loader.image {
                // Ja attēls tiek veiksmīgi ielādēts, parāda to
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                // Ja attēls nav ielādēts, parāda noklusējuma attēlu
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.gray)
            }
        }
    }
}

