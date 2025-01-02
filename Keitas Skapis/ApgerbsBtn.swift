
import SwiftUI

// MARK: - Skats apģērba attēlošanai
struct clothingItemButton: View {
    // MARK: - Parametri
    
    let clothingItem: ClothingItem
    let isSelected: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    @State private var image: UIImage?

    var body: some View {
        VStack {
            // Apģērba attēls, ja tas ir pievienots un ielādēts
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
            } else { // Noklusējuma attēls
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.gray)
                    .opacity(0.5)
                    .padding(.top, 15)
                    .padding(.bottom, 10)
            }

            // Nosaukums
            Text(clothingItem.name)
                .frame(width: 80, height: 30)
                .multilineTextAlignment(.center)
        }
        .frame(width: 90, height: 120)
        .background(isSelected ? Color.blue.opacity(0.3) : Color(.white))
        .cornerRadius(8)
        .contentShape(Rectangle())
        .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
        .onTapGesture {
            onTap() // Reģistrē pieskārienu
        }
        .onLongPressGesture {
            onLongPress() // Reģistrē turēšanu
        }
        .onAppear {
            loadImage() // Ielādē attēlu, kad skats parādās
        }
    }

    // MARK: - Palīgfunkcijas
    
    // Asinhroni ielādē apģērba attēlu
    private func loadImage() {
        clothingItem.loadImage { loadedImage in
            self.image = loadedImage
        }
    }
}




