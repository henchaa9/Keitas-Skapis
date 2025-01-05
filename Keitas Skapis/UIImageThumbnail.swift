import SwiftUI

extension UIImage {
    // Atgriež attēla mazāku versiju ar pareizu malu attiecību
    /// - Parameter maxPixelSize: Maksimālais izmērs pikseļos.
    func thumbnailImage(maxPixelSize: CGFloat) -> UIImage? {
        let aspectRatio = size.width / size.height

        var newWidth = maxPixelSize
        var newHeight = maxPixelSize

        // Pielāgo izmērus, lai būtu pareiza malu attiecība
        if aspectRatio > 1 {
            // Ainava
            newHeight = maxPixelSize / aspectRatio
        } else {
            // Portrets
            newWidth = maxPixelSize * aspectRatio
        }

        // Zīmē mazo attēla versiju izmantojot UIGraphicsImageRenderer
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: newWidth, height: newHeight))
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: CGSize(width: newWidth, height: newHeight)))
        }
    }
}
