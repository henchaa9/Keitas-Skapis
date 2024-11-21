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
class Kategorija: Identifiable, Hashable, Codable {
    @Attribute var id: UUID = UUID()
    @Attribute var nosaukums: String
    @Attribute(.externalStorage) var attels: Data?
    @Attribute var removeBackground: Bool = false

    @Relationship var apgerbi: [Apgerbs] = []

    init(nosaukums: String = "Jauna Kategorija", attels: Data? = nil, removeBackground: Bool = false) {
        self.nosaukums = nosaukums
        self.attels = attels
        self.removeBackground = removeBackground
    }

    // Computed property to get the UIImage from attels
    var image: UIImage? {
        get { attels.flatMap { UIImage(data: $0) } }
        set { attels = newValue?.pngData() }
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

    static func == (lhs: Kategorija, rhs: Kategorija) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // Exclude relationships from coding to prevent cyclical references
    enum CodingKeys: String, CodingKey {
        case id, nosaukums, attels, removeBackground
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.nosaukums = try container.decode(String.self, forKey: .nosaukums)
        self.attels = try container.decodeIfPresent(Data.self, forKey: .attels)
        self.removeBackground = try container.decode(Bool.self, forKey: .removeBackground)
        self.apgerbi = []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(nosaukums, forKey: .nosaukums)
        try container.encodeIfPresent(attels, forKey: .attels)
        try container.encode(removeBackground, forKey: .removeBackground)
    }
}


struct Krasa: Codable, Hashable {
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



enum Sezona: String, CaseIterable, Codable {
    case vasara = "Vasara"
    case rudens = "Rudens"
    case ziema = "Ziema"
    case pavasaris = "Pavasaris"
}


@Model
class Apgerbs: Identifiable, Hashable, Codable {
    @Attribute var id: UUID = UUID()
    @Attribute var nosaukums: String
    @Attribute var piezimes: String
    @Attribute var krasa: Krasa
    @Attribute var stavoklis: Int
    @Attribute var gludinams: Bool
    @Attribute var izmers: Int
    @Attribute var sezona: [Sezona]
    @Attribute var pedejoreizVilkts: Date
    @Attribute var mazgajas: Bool
    @Attribute var netirs: Bool
    @Attribute var removeBackground: Bool = false
    @Attribute(.externalStorage) var attels: Data?

    @Relationship var kategorijas: [Kategorija] = []
    @Relationship var dienas: [Diena] = []

    init(
        nosaukums: String = "jauns apgerbs",
        piezimes: String = "",
        krasa: Krasa,
        stavoklis: Int = 0,
        gludinams: Bool = true,
        sezona: [Sezona] = [],
        izmers: Int = 0,
        pedejoreizVilkts: Date = .now,
        netirs: Bool = false,
        mazgajas: Bool = false,
        attels: Data? = nil,
        removeBackground: Bool = false
    ) {
        self.nosaukums = nosaukums
        self.piezimes = piezimes
        self.krasa = krasa
        self.stavoklis = stavoklis
        self.gludinams = gludinams
        self.sezona = sezona
        self.izmers = izmers
        self.pedejoreizVilkts = pedejoreizVilkts
        self.mazgajas = mazgajas
        self.netirs = netirs
        self.attels = attels
        self.removeBackground = removeBackground
    }

    // Computed property to get the UIImage from attels
    var image: UIImage? {
        get { attels.flatMap { UIImage(data: $0) } }
        set { attels = newValue?.pngData() }
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

    static func == (lhs: Apgerbs, rhs: Apgerbs) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    enum CodingKeys: String, CodingKey {
        case id, nosaukums, piezimes, krasa, stavoklis, gludinams, izmers, sezona, pedejoreizVilkts, mazgajas, netirs, attels, removeBackground
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.nosaukums = try container.decode(String.self, forKey: .nosaukums)
        self.piezimes = try container.decode(String.self, forKey: .piezimes)
        self.krasa = try container.decode(Krasa.self, forKey: .krasa)
        self.stavoklis = try container.decode(Int.self, forKey: .stavoklis)
        self.gludinams = try container.decode(Bool.self, forKey: .gludinams)
        self.izmers = try container.decode(Int.self, forKey: .izmers)
        self.sezona = try container.decode([Sezona].self, forKey: .sezona)
        self.pedejoreizVilkts = try container.decode(Date.self, forKey: .pedejoreizVilkts)
        self.mazgajas = try container.decode(Bool.self, forKey: .mazgajas)
        self.netirs = try container.decode(Bool.self, forKey: .netirs)
        self.attels = try container.decodeIfPresent(Data.self, forKey: .attels)
        self.removeBackground = try container.decode(Bool.self, forKey: .removeBackground)
        self.kategorijas = []
        self.dienas = []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(nosaukums, forKey: .nosaukums)
        try container.encode(piezimes, forKey: .piezimes)
        try container.encode(krasa, forKey: .krasa)
        try container.encode(stavoklis, forKey: .stavoklis)
        try container.encode(gludinams, forKey: .gludinams)
        try container.encode(izmers, forKey: .izmers)
        try container.encode(sezona, forKey: .sezona)
        try container.encode(pedejoreizVilkts, forKey: .pedejoreizVilkts)
        try container.encode(mazgajas, forKey: .mazgajas)
        try container.encode(netirs, forKey: .netirs)
        try container.encodeIfPresent(attels, forKey: .attels)
        try container.encode(removeBackground, forKey: .removeBackground)
    }
}


@Model
class Diena: Codable {
    @Attribute var datums: Date
    @Attribute var piezimes: String

    @Relationship var apgerbi: [Apgerbs] = []

    init(datums: Date, piezimes: String, apgerbi: [Apgerbs] = []) {
        self.datums = datums
        self.piezimes = piezimes
        self.apgerbi = apgerbi
    }

    enum CodingKeys: String, CodingKey {
        case datums, piezimes
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.datums = try container.decode(Date.self, forKey: .datums)
        self.piezimes = try container.decode(String.self, forKey: .piezimes)
        self.apgerbi = []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(datums, forKey: .datums)
        try container.encode(piezimes, forKey: .piezimes)
    }
}


@Model
class Milakais: Codable {
    @Attribute var nosaukums: String
    @Attribute var piezimes: String

    @Relationship var apgerbi: [Apgerbs] = []

    init(nosaukums: String, piezimes: String, apgerbi: [Apgerbs] = []) {
        self.nosaukums = nosaukums
        self.piezimes = piezimes
        self.apgerbi = apgerbi
    }

    enum CodingKeys: String, CodingKey {
        case nosaukums, piezimes
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.nosaukums = try container.decode(String.self, forKey: .nosaukums)
        self.piezimes = try container.decode(String.self, forKey: .piezimes)
        self.apgerbi = []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(nosaukums, forKey: .nosaukums)
        try container.encode(piezimes, forKey: .piezimes)
    }
}


