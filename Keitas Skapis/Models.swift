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

// MARK: - ClothingCategory Model

/// Represents a category of clothing items with optional image and background removal capability.
@Model
class ClothingCategory: Identifiable, Hashable, Codable {
    // MARK: - Attributes
    
    @Attribute var id: UUID = UUID() // Unique identifier for the category
    @Attribute var name: String // Name of the category
    @Attribute(.externalStorage) var picture: Data? // Optional image data stored externally
    @Attribute var removeBackground: Bool = false // Flag to indicate if background should be removed from the image
    
    // MARK: - Relationships
    
    @Relationship var categoryClothingItems: [ClothingItem] = [] // Clothing items associated with this category
    
    // MARK: - Initializer
    
    /// Initializes a new ClothingCategory with optional parameters.
    /// - Parameters:
    ///   - name: The name of the category. Defaults to "Jauna Kategorija".
    ///   - picture: Optional image data for the category.
    ///   - removeBackground: Indicates whether to remove the background from the image. Defaults to `false`.
    init(name: String = "Jauna Kategorija", picture: Data? = nil, removeBackground: Bool = false) {
        self.name = name
        self.picture = picture
        self.removeBackground = removeBackground
    }
    
    // MARK: - Computed Properties
    
    /// Converts the stored image data to a UIImage.
    var image: UIImage? {
        get { picture.flatMap { UIImage(data: $0) } }
        set { picture = newValue?.pngData() }
    }
    
    /// Returns the displayed image, applying background removal if enabled.
    var displayedImage: UIImage? {
        if removeBackground, let image = self.image {
            return removeBackground(from: image) // Helper Function
        }
        return self.image
    }
    
    // MARK: - Background Removal Functions
    
    /// Removes the background from the provided image using Vision and CoreImage.
    /// - Parameter image: The original UIImage from which to remove the background.
    /// - Returns: A new UIImage with the background removed, or the original image if removal fails.
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

    /// Creates a mask image using Vision's foreground instance mask request.
    /// - Parameter inputImage: The CIImage to process.
    /// - Returns: A CIImage mask or nil if creation fails.
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

    /// Applies the mask to the original image to remove the background.
    /// - Parameters:
    ///   - mask: The CIImage mask to apply.
    ///   - image: The original CIImage.
    /// - Returns: A new CIImage with the background removed.
    private func applyMask(mask: CIImage, to image: CIImage) -> CIImage {
        let filter = CIFilter.blendWithMask()
        filter.inputImage = image
        filter.maskImage = mask
        filter.backgroundImage = CIImage.empty()
        return filter.outputImage!
    }

    /// Converts a CIImage back to a UIImage with the original orientation.
    /// - Parameters:
    ///   - ciImage: The CIImage to convert.
    ///   - originalOrientation: The original orientation of the UIImage.
    /// - Returns: A new UIImage created from the CIImage.
    private func convertToUIImage(ciImage: CIImage, originalOrientation: UIImage.Orientation = .up) -> UIImage? {
        guard let cgImage = CIContext(options: nil).createCGImage(ciImage, from: ciImage.extent) else {
            print("Failed to render CGImage")
            return nil
        }
        return UIImage(cgImage: cgImage, scale: 1.0, orientation: originalOrientation)
    }
    
    // MARK: - Hashable & Equatable
    
    static func == (lhs: ClothingCategory, rhs: ClothingCategory) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: - Codable
    
    /// Defines the coding keys, excluding relationships to prevent cyclical references.
    enum CodingKeys: String, CodingKey {
        case id, name, picture, removeBackground
    }
    
    /// Initializes a ClothingCategory from a decoder, excluding relationships.
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.picture = try container.decodeIfPresent(Data.self, forKey: .picture)
        self.removeBackground = try container.decode(Bool.self, forKey: .removeBackground)
        self.categoryClothingItems = []
    }
    
    /// Encodes the ClothingCategory, excluding relationships.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(picture, forKey: .picture)
        try container.encode(removeBackground, forKey: .removeBackground)
    }
}

// MARK: - CustomColor Struct

/// Represents a color with red, green, blue, and alpha components.
struct CustomColor: Codable, Hashable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    /// Converts the CustomColor to a SwiftUI Color.
    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }

    /// Initializes a CustomColor with specific color components.
    /// - Parameters:
    ///   - red: Red component (0.0 - 1.0).
    ///   - green: Green component (0.0 - 1.0).
    ///   - blue: Blue component (0.0 - 1.0).
    ///   - alpha: Alpha component (0.0 - 1.0).
    init(red: Double, green: Double, blue: Double, alpha: Double) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    /// Initializes a CustomColor from a SwiftUI Color.
    /// - Parameter color: The SwiftUI Color to convert.
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

// MARK: - Season Enum

/// Represents the seasons for which a clothing item is suitable.
enum Season: String, CaseIterable, Codable {
    case summer = "Vasara"
    case fall = "Rudens"
    case winter = "Ziema"
    case spring = "Pavasaris"
}

// MARK: - ClothingItem Model

/// Represents an individual clothing item with various attributes and relationships.
@Model
class ClothingItem: Identifiable, Hashable, Codable {
    // MARK: - Attributes
    
    @Attribute var id: UUID = UUID() // Unique identifier for the clothing item
    @Attribute var name: String // Name of the clothing item
    @Attribute var notes: String // Additional notes about the item
    @Attribute var color: CustomColor // Color of the clothing item
    @Attribute var status: Int // Status indicator (e.g., available, worn, etc.)
    @Attribute var ironable: Bool // Indicates if the item can be ironed
    @Attribute var size: Int // Size of the clothing item
    @Attribute var season: [Season] // Seasons suitable for the item
    @Attribute var lastWorn: Date // Date when the item was last worn
    @Attribute var washing: Bool // Indicates if the item is being washed
    @Attribute var dirty: Bool // Indicates if the item is dirty
    @Attribute var removeBackground: Bool = false // Flag to remove background from the image
    @Attribute var isFavorite: Bool = false // Indicates if the item is marked as favorite
    @Attribute(.externalStorage) var picture: Data? // Optional image data stored externally
    
    // MARK: - Relationships
    
    @Relationship var clothingItemCategories: [ClothingCategory] = [] // Categories associated with this item
    @Relationship(inverse: \Day.dayClothingItems) var clothingItemDays: [Day] = [] // Days when the item was worn
    
    // MARK: - Static Properties
    
    static var imageCache = NSCache<NSString, UIImage>() // In-memory cache for images
    
    // MARK: - Initializer
    
    /// Initializes a new ClothingItem with optional parameters.
    /// - Parameters:
    ///   - name: Name of the clothing item. Defaults to "jauns apgerbs".
    ///   - notes: Additional notes. Defaults to an empty string.
    ///   - color: Color of the clothing item.
    ///   - status: Status indicator. Defaults to `0`.
    ///   - ironable: Indicates if the item can be ironed. Defaults to `true`.
    ///   - season: Seasons suitable for the item. Defaults to an empty array.
    ///   - size: Size of the clothing item. Defaults to `0`.
    ///   - lastWorn: Date when the item was last worn. Defaults to `.now`.
    ///   - dirty: Indicates if the item is dirty. Defaults to `false`.
    ///   - washing: Indicates if the item is being washed. Defaults to `false`.
    ///   - picture: Optional image data. Defaults to `nil`.
    ///   - removeBackground: Flag to remove background from the image. Defaults to `false`.
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
    
    // MARK: - Image Loading
    
    /// Loads the image associated with the clothing item, applying background removal if enabled.
    /// Utilizes caching to improve performance.
    /// - Parameter completion: Completion handler with the loaded UIImage.
    func loadImage(completion: @escaping (UIImage?) -> Void) {
        // Check if the image is already cached
        if let cachedImage = ClothingItem.imageCache.object(forKey: self.id.uuidString as NSString) {
            completion(cachedImage)
            return
        }

        // Load the image asynchronously
        DispatchQueue.global(qos: .background).async {
            var image: UIImage?

            if let imageData = self.picture, let uiImage = UIImage(data: imageData) {
                if self.removeBackground {
                    image = self.removeBackground(from: uiImage) // Helper Function
                } else {
                    image = uiImage
                }
            }

            // Cache the image if available
            if let imageToCache = image {
                ClothingItem.imageCache.setObject(imageToCache, forKey: self.id.uuidString as NSString)
            }

            // Return the image on the main thread
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
    
    /// Reloads the image by removing it from the cache and reloading it.
    func reloadImage() {
        // Remove the image from the cache
        ClothingItem.imageCache.removeObject(forKey: self.id.uuidString as NSString)
        
        // Reload and re-cache the image
        loadImage { _ in }
    }
    
    // MARK: - Background Removal Functions
    
    /// Removes the background from the provided image using Vision and CoreImage.
    /// - Parameter image: The original UIImage from which to remove the background.
    /// - Returns: A new UIImage with the background removed, or the original image if removal fails.
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

    /// Creates a mask image using Vision's foreground instance mask request.
    /// - Parameter inputImage: The CIImage to process.
    /// - Returns: A CIImage mask or nil if creation fails.
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

    /// Applies the mask to the original image to remove the background.
    /// - Parameters:
    ///   - mask: The CIImage mask to apply.
    ///   - image: The original CIImage.
    /// - Returns: A new CIImage with the background removed.
    private func applyMask(mask: CIImage, to image: CIImage) -> CIImage {
        let filter = CIFilter.blendWithMask()
        filter.inputImage = image
        filter.maskImage = mask
        filter.backgroundImage = CIImage.empty()
        return filter.outputImage!
    }

    /// Converts a CIImage back to a UIImage with the original orientation.
    /// - Parameters:
    ///   - ciImage: The CIImage to convert.
    ///   - originalOrientation: The original orientation of the UIImage.
    /// - Returns: A new UIImage created from the CIImage.
    private func convertToUIImage(ciImage: CIImage, originalOrientation: UIImage.Orientation = .up) -> UIImage? {
        guard let cgImage = CIContext(options: nil).createCGImage(ciImage, from: ciImage.extent) else {
            print("Failed to render CGImage")
            return nil
        }
        return UIImage(cgImage: cgImage, scale: 1.0, orientation: originalOrientation)
    }
    
    // MARK: - Hashable & Equatable
    
    static func == (lhs: ClothingItem, rhs: ClothingItem) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: - Codable
    
    /// Defines the coding keys, including relationships.
    enum CodingKeys: String, CodingKey {
        case id, name, notes, color, status, ironable, size, season, lastWorn, washing, dirty, picture, removeBackground, clothingItemDays
    }
    
    /// Initializes a ClothingItem from a decoder, excluding relationships.
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
    
    /// Encodes the ClothingItem, including relationships.
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
        try container.encode(clothingItemDays, forKey: .clothingItemDays)
    }
}

// MARK: - Day Model

/// Represents a day with associated clothing items and notes.
@Model
class Day: Codable {
    // MARK: - Attributes
    
    @Attribute var id: UUID = UUID() // Unique identifier for the day
    @Attribute var date: Date // The date of the day
    @Attribute var notes: String // Additional notes for the day
    
    // MARK: - Relationships
    
    @Relationship var dayClothingItems: [ClothingItem] = [] // Clothing items worn on this day
    
    // MARK: - Initializer
    
    /// Initializes a new Day with specified parameters.
    /// - Parameters:
    ///   - date: The date of the day.
    ///   - notes: Additional notes for the day.
    ///   - clothingItems: Clothing items associated with the day. Defaults to an empty array.
    init(date: Date, notes: String, clothingItems: [ClothingItem] = []) {
        self.date = date
        self.notes = notes
        self.dayClothingItems = clothingItems
    }
    
    // MARK: - Coding
    
    /// Defines the coding keys.
    enum CodingKeys: String, CodingKey {
        case id, date, notes, dayClothingItems
    }
    
    /// Initializes a Day from a decoder, excluding relationships.
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.date = try container.decode(Date.self, forKey: .date)
        self.notes = try container.decode(String.self, forKey: .notes)
        self.dayClothingItems = []
    }
    
    /// Encodes the Day, including relationships.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(notes, forKey: .notes)
        try container.encode(dayClothingItems, forKey: .dayClothingItems)
    }
}


