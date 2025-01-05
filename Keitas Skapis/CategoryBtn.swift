
import SwiftUI

// MARK: - Skats kategorijas attēlošanai
struct CategoryButton: View {
    let clothingCategory: ClothingCategory
    let isSelected: Bool
    let onLongPress: (ClothingCategory) -> Void
    let toggleSelection: (ClothingCategory) -> Void
    
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
                    .padding(.top, 20)
                    .padding(.bottom, 10)
            }
            
            Text(clothingCategory.name)
                .frame(width: 80, height: 30)
                .multilineTextAlignment(.center)
        }
        .frame(width: 90, height: 120)
        .background(isSelected ? Color.blue.opacity(0.3) : Color(.white))
        .cornerRadius(8)
        .contentShape(Rectangle())
        .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
        .onTapGesture {
            toggleSelection(clothingCategory)
        }
        .simultaneousGesture(
            LongPressGesture().onEnded { _ in
                onLongPress(clothingCategory)
            }
        )
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        // Same logic as ClothingItem
        if let thumbData = clothingCategory.thumbnailPicture,
           let uiImage = UIImage(data: thumbData) {
            // Thumbnail is available
            self.image = uiImage
        } else {
            // No thumbnail, so load full image asynchronously
            clothingCategory.loadImage { loadedImage in
                self.image = loadedImage
            }
        }
    }
}



