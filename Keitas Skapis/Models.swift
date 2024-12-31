//
//  Models.swift
//  Keitas Skapis
//
//  Created by Henrijs Obolevics on 06/10/2024.
//

import Foundation
import SwiftData
import SwiftUI
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

@Model
class ClothingCategory: Identifiable, Hashable, Codable {
    @Attribute var id: UUID = UUID()
    @Attribute var name: String
    @Attribute(.externalStorage) var picture: Data?
    @Attribute var removeBackground: Bool = false

    @Relationship var categoryClothingItems: [ClothingItem] = []

    init(name: String = "Jauna Kategorija", picture: Data? = nil, removeBackground: Bool = false) {
        self.name = name
        self.picture = picture
        self.removeBackground = removeBackground
    }

    // Computed property to get the UIImage from attels
    var image: UIImage? {
        get { picture.flatMap { UIImage(data: $0) } }
        set { picture = newValue?.pngData() }
    }
    
    // Computed property to return the displayed image with or without background
    var displayedImage: UIImage? {
        if removeBackground, let image = self.image {
            return removeBackground(from: image)
        }
        return self.image
    }
    
    // Background removal functions
    private func removeBackground(from image: UIImage) -> UIImage? {
        guard let inputImage = CIImage(image: image) else {
            print("Failed to create CIImage")
            return image
        }

        guard let maskImage = createMask(from: inputImage) else {
            print("Failed to create mask")
            return image
        }

        let outputImage = applyMask(mask: maskImage, to: inputImage)
        return convertToUIImage(ciImage: outputImage, originalOrientation: image.imageOrientation)
    }

    private func createMask(from inputImage: CIImage) -> CIImage? {
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(ciImage: inputImage)
        do {
            try handler.perform([request])
            if let result = request.results?.first {
                let mask = try result.generateScaledMaskForImage(forInstances: result.allInstances, from: handler)
                return CIImage(cvPixelBuffer: mask)
            }
        } catch {
            print(error)
        }
        return nil
    }

    private func applyMask(mask: CIImage, to image: CIImage) -> CIImage {
        let filter = CIFilter.blendWithMask()
        filter.inputImage = image
        filter.maskImage = mask
        filter.backgroundImage = CIImage.empty()
        return filter.outputImage!
    }

    private func convertToUIImage(ciImage: CIImage, originalOrientation: UIImage.Orientation = .up) -> UIImage? {
        guard let cgImage = CIContext(options: nil).createCGImage(ciImage, from: ciImage.extent) else {
            print("Failed to render CGImage")
            return nil
        }
        return UIImage(cgImage: cgImage, scale: 1.0, orientation: originalOrientation)
    }

    static func == (lhs: ClothingCategory, rhs: ClothingCategory) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // Exclude relationships from coding to prevent cyclical references
    enum CodingKeys: String, CodingKey {
        case id, name, picture, removeBackground
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.picture = try container.decodeIfPresent(Data.self, forKey: .picture)
        self.removeBackground = try container.decode(Bool.self, forKey: .removeBackground)
        self.categoryClothingItems = []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(picture, forKey: .picture)
        try container.encode(removeBackground, forKey: .removeBackground)
    }
}


struct CustomColor: Codable, Hashable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    // Computed property to get SwiftUI Color
    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }

    // Initializer from components
    init(red: Double, green: Double, blue: Double, alpha: Double) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    // Initializer from Color
    init(color: Color) {
        let uiColor = UIColor(color)
        var redComponent: CGFloat = 0
        var greenComponent: CGFloat = 0
        var blueComponent: CGFloat = 0
        var alphaComponent: CGFloat = 0
        uiColor.getRed(&redComponent, green: &greenComponent, blue: &blueComponent, alpha: &alphaComponent)
        self.red = Double(redComponent)
        self.green = Double(greenComponent)
        self.blue = Double(blueComponent)
        self.alpha = Double(alphaComponent)
    }
}



enum Season: String, CaseIterable, Codable {
    case summer = "Vasara"
    case fall = "Rudens"
    case winter = "Ziema"
    case spring = "Pavasaris"
}


@Model
class ClothingItem: Identifiable, Hashable, Codable {
    @Attribute var id: UUID = UUID()
    @Attribute var name: String
    @Attribute var notes: String
    @Attribute var color: CustomColor
    @Attribute var status: Int
    @Attribute var ironable: Bool
    @Attribute var size: Int
    @Attribute var season: [Season]
    @Attribute var lastWorn: Date
    @Attribute var washing: Bool
    @Attribute var dirty: Bool
    @Attribute var removeBackground: Bool = false
    @Attribute var isFavorite: Bool = false 
    @Attribute(.externalStorage) var picture: Data?

    @Relationship var clothingItemCategories: [ClothingCategory] = []
    @Relationship var clothingItemDays: [Day] = []
    
    static var imageCache = NSCache<NSString, UIImage>()

    init(
        name: String = "jauns apgerbs",
        notes: String = "",
        color: CustomColor,
        status: Int = 0,
        ironable: Bool = true,
        season: [Season] = [],
        size: Int = 0,
        lastWorn: Date = .now,
        dirty: Bool = false,
        washing: Bool = false,
        picture: Data? = nil,
        removeBackground: Bool = false
    ) {
        self.name = name
        self.notes = notes
        self.color = color
        self.status = status
        self.ironable = ironable
        self.season = season
        self.size = size
        self.lastWorn = lastWorn
        self.washing = washing
        self.dirty = dirty
        self.picture = picture
        self.removeBackground = removeBackground
    }
    
    func loadImage(completion: @escaping (UIImage?) -> Void) {
        if let cachedImage = ClothingItem.imageCache.object(forKey: self.id.uuidString as NSString) {
            completion(cachedImage)
            return
        }

        DispatchQueue.global(qos: .background).async {
            var image: UIImage?

            if let imageData = self.picture, let uiImage = UIImage(data: imageData) {
                if self.removeBackground {
                    image = self.removeBackground(from: uiImage)
                } else {
                    image = uiImage
                }
            }

            // Cache the image
            if let imageToCache = image {
                ClothingItem.imageCache.setObject(imageToCache, forKey: self.id.uuidString as NSString)
            }

            DispatchQueue.main.async {
                completion(image)
            }
        }
    }

    func reloadImage() {
        // Remove from the in-memory cache
        ClothingItem.imageCache.removeObject(forKey: self.id.uuidString as NSString)
        
        // Then call loadImage again to regenerate and re-cache
        loadImage {_ in}
    }

    
    // Background removal functions
    private func removeBackground(from image: UIImage) -> UIImage? {
        guard let inputImage = CIImage(image: image) else {
            print("Failed to create CIImage")
            return image
        }

        guard let maskImage = createMask(from: inputImage) else {
            print("Failed to create mask")
            return image
        }

        let outputImage = applyMask(mask: maskImage, to: inputImage)
        return convertToUIImage(ciImage: outputImage, originalOrientation: image.imageOrientation)
    }

    private func createMask(from inputImage: CIImage) -> CIImage? {
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(ciImage: inputImage)
        do {
            try handler.perform([request])
            if let result = request.results?.first {
                let mask = try result.generateScaledMaskForImage(forInstances: result.allInstances, from: handler)
                return CIImage(cvPixelBuffer: mask)
            }
        } catch {
            print(error)
        }
        return nil
    }

    private func applyMask(mask: CIImage, to image: CIImage) -> CIImage {
        let filter = CIFilter.blendWithMask()
        filter.inputImage = image
        filter.maskImage = mask
        filter.backgroundImage = CIImage.empty()
        return filter.outputImage!
    }

    private func convertToUIImage(ciImage: CIImage, originalOrientation: UIImage.Orientation = .up) -> UIImage? {
        guard let cgImage = CIContext(options: nil).createCGImage(ciImage, from: ciImage.extent) else {
            print("Failed to render CGImage")
            return nil
        }
        return UIImage(cgImage: cgImage, scale: 1.0, orientation: originalOrientation)
    }

    static func == (lhs: ClothingItem, rhs: ClothingItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    enum CodingKeys: String, CodingKey {
        case id, name, notes, color, status, ironable, size, season, lastWorn, washing, dirty, picture, removeBackground
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.notes = try container.decode(String.self, forKey: .notes)
        self.color = try container.decode(CustomColor.self, forKey: .color)
        self.status = try container.decode(Int.self, forKey: .status)
        self.ironable = try container.decode(Bool.self, forKey: .ironable)
        self.size = try container.decode(Int.self, forKey: .size)
        self.season = try container.decode([Season].self, forKey: .season)
        self.lastWorn = try container.decode(Date.self, forKey: .lastWorn)
        self.washing = try container.decode(Bool.self, forKey: .washing)
        self.dirty = try container.decode(Bool.self, forKey: .dirty)
        self.picture = try container.decodeIfPresent(Data.self, forKey: .picture)
        self.removeBackground = try container.decode(Bool.self, forKey: .removeBackground)
        self.clothingItemCategories = []
        self.clothingItemDays = []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(notes, forKey: .notes)
        try container.encode(color, forKey: .color)
        try container.encode(status, forKey: .status)
        try container.encode(ironable, forKey: .ironable)
        try container.encode(size, forKey: .size)
        try container.encode(season, forKey: .season)
        try container.encode(lastWorn, forKey: .lastWorn)
        try container.encode(washing, forKey: .washing)
        try container.encode(dirty, forKey: .dirty)
        try container.encodeIfPresent(picture, forKey: .picture)
        try container.encode(removeBackground, forKey: .removeBackground)
    }
}


@Model
class Day: Codable {
    @Attribute var date: Date
    @Attribute var notes: String

    @Relationship var dayClothingItems: [ClothingItem] = []

    init(date: Date, notes: String, clothingItems: [ClothingItem] = []) {
        self.date = date
        self.notes = notes
        self.dayClothingItems = clothingItems
    }

    enum CodingKeys: String, CodingKey {
        case date, notes
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.date = try container.decode(Date.self, forKey: .date)
        self.notes = try container.decode(String.self, forKey: .notes)
        self.dayClothingItems = []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(date, forKey: .date)
        try container.encode(notes, forKey: .notes)
    }
}


