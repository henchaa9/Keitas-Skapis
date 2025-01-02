
import Foundation
import SwiftData
import SwiftUI
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - Datu modeļi

// MARK: - ClothingCategory Modelis

// Kategorija
@Model
class ClothingCategory: Identifiable, Hashable, Codable {
    // MARK: - Atribūti
    
    @Attribute var id: UUID = UUID() // ID
    @Attribute var name: String // Nosaukums
    @Attribute(.externalStorage) var picture: Data? // Neobligāti attēla dati, saglabāti atsevišķi
    @Attribute var removeBackground: Bool = false // Patiesumvērtība fona noņemšanas vērtības saglabāšanai
    
    // MARK: - Relācijas
    
    @Relationship var categoryClothingItems: [ClothingItem] = [] // Apģērbi, kas piesaistīti kategorijai
    
    // MARK: - Initializer
    
    // Inicializē jaunu kategoriju ar neobligātiem parametriem
    /// - Parameters:
    ///   - name: Nosaukums, pēc noklusējuma "Jauna Kategorija".
    ///   - picture: Neobligāti attēla dati.
    ///   - removeBackground: Norāda, vai attēlam jānoņem fons, pēc noklusējuma `false`.
    init(name: String = "Jauna Kategorija", picture: Data? = nil, removeBackground: Bool = false) {
        self.name = name
        self.picture = picture
        self.removeBackground = removeBackground
    }
    
    // MARK: - Aprēķināmie parametri
    
    // Pārvērš attēlu par UIImage
    var image: UIImage? {
        get { picture.flatMap { UIImage(data: $0) } }
        set { picture = newValue?.pngData() }
    }
    
    // Atgriež attēlojamo attēlu, ar noņemtu fonu pēc vajadzības
    var displayedImage: UIImage? {
        if removeBackground, let image = self.image {
            return removeBackground(from: image) // Helper Function
        }
        return self.image
    }
    
    // MARK: - Fona noņemšanas funkcijas
    
    // Noņem fonu no attēla izmantojot Vision un CoreImage
    /// - Parameter image: Oriģinālais UIImage attēls no kura noņemt fonu.
    /// - Returns: Jauns UIImage ar noņemtu fonu vai oriģinālais attēls, ja noņemšana neizdodas.
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

    // Izveido attēla masku izmantojot Vision.
    /// - Parameter inputImage: CIImage attēls ko apstrādāt.
    /// - Returns: CIImage maska vai nil, ja izveidošana neizdodas.
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

    // Pievieno masku oriģinālajam attēlam, lai noņemtu fonu.
    /// - Parameters:
    ///   - mask: CIImage maska, ko pievienot.
    ///   - image: Oriģinālais CIImage attēls.
    /// - Returns: Jauns CIImage attēls ar noņemtu fonu.
    private func applyMask(mask: CIImage, to image: CIImage) -> CIImage {
        let filter = CIFilter.blendWithMask()
        filter.inputImage = image
        filter.maskImage = mask
        filter.backgroundImage = CIImage.empty()
        return filter.outputImage!
    }

    // Pārvērš CIImage atpakaļ uz UIImage ar oriģinālu orientāciju.
    /// - Parameters:
    ///   - ciImage: CIImage attēls ko pārvērst.
    ///   - originalOrientation: Oriģinālā UIImage attēla orientācija.
    /// - Returns: Jauns UIImage attēls izveidots no CIImage.
    private func convertToUIImage(ciImage: CIImage, originalOrientation: UIImage.Orientation = .up) -> UIImage? {
        guard let cgImage = CIContext(options: nil).createCGImage(ciImage, from: ciImage.extent) else {
            print("Failed to render CGImage")
            return nil
        }
        return UIImage(cgImage: cgImage, scale: 1.0, orientation: originalOrientation)
    }
    
    // MARK: - Nodrošina atbilstību Hashable & Equatable, lai pareizi strādātu relācijas utt.
    
    static func == (lhs: ClothingCategory, rhs: ClothingCategory) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: - Nodrošina atbilstību Codable
    
    // Atslēgas, izņemot relācijas, lai nenotiktu cikliskas references
    enum CodingKeys: String, CodingKey {
        case id, name, picture, removeBackground
    }
    
    // Inicializē kategoriju no Decoder (atkodē uz izmantojamām vērtībām), izņemot relācijas
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.picture = try container.decodeIfPresent(Data.self, forKey: .picture)
        self.removeBackground = try container.decode(Bool.self, forKey: .removeBackground)
        self.categoryClothingItems = []
    }
    
    // Kodē kategoriju, izņemot relācijas
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(picture, forKey: .picture)
        try container.encode(removeBackground, forKey: .removeBackground)
    }
}

// MARK: - CustomColor Struct

// Struct, kas attēlo krāsu, kuru var pievienot apģērbam
struct CustomColor: Codable, Hashable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    // Pārvērš krāsu par SwiftUI krāsu.
    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }

    /// Inicializē krāsu ar specifiskām krāsas sastāvdaļām/kanāliem.
    /// - Parameters:
    ///   - red: Red kanāls (0.0 - 1.0).
    ///   - green: Green kanāls (0.0 - 1.0).
    ///   - blue: Blue kanāls (0.0 - 1.0).
    ///   - alpha: Alpha kanāls (0.0 - 1.0).
    init(red: Double, green: Double, blue: Double, alpha: Double) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    // Inicializē krāsu no SwiftUI krāsas.
    /// - Parameter color: SwiftUI krāsa, kuru pārvērst.
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

// Attēlo sezonas, kuras var pievienot apģērbam.
enum Season: String, CaseIterable, Codable {
    case summer = "Vasara"
    case fall = "Rudens"
    case winter = "Ziema"
    case spring = "Pavasaris"
}

// MARK: - ClothingItem Modelis

// Apģērbs
@Model
class ClothingItem: Identifiable, Hashable, Codable {
    // MARK: - Atribūti
    
    @Attribute var id: UUID = UUID() // ID
    @Attribute var name: String // Nosaukums
    @Attribute var notes: String // Piezīmes
    @Attribute var color: CustomColor // Krāsa
    @Attribute var status: Int // Stāvoklis tīrs/netīrs/mazgājas
    @Attribute var ironable: Bool // Gludināms/Negludināms
    @Attribute var size: Int // Izmērs XS/S/M/L/XL
    @Attribute var season: [Season] // Sezona vasara/rudens/ziema/pavasaris
    @Attribute var lastWorn: Date // Pēdējoreiz vilkts datums
    @Attribute var washing: Bool // Mazgājas
    @Attribute var dirty: Bool // Netīrs
    @Attribute var removeBackground: Bool = false // Patiesumvērtība fona noņemšanai
    @Attribute var isFavorite: Bool = false // Mīļākais
    @Attribute(.externalStorage) var picture: Data? // Neobligāti attēla dati, glabāti atsevišķi
    
    // MARK: - Relācijas
    
    @Relationship var clothingItemCategories: [ClothingCategory] = [] // Apģērbam piesaistītās kategorijas
    @Relationship(inverse: \Day.dayClothingItems) var clothingItemDays: [Day] = [] // Apģērbam piesaistītās dienas
    
    // MARK: - Statiskie parametri
    
    static var imageCache = NSCache<NSString, UIImage>() // Atmiņā esošs cache priekš attēliem
    
    // MARK: - Initializer
    
    // Inicializē apģērbu ar neobligātiem parametriem
    /// - Parameters:
    ///   - name: Nosaukums, pēc noklusējuma "Jauns Apģērbs".
    ///   - notes: Piezīmes, pēc noklusējuma tukša simbolu virkne.
    ///   - color: Krāsa, pēc noklusējuma balta.
    ///   - status: Stāvoklis, pēc noklusējuma `0`.
    ///   - ironable: Gludināms/Negludināms, pēc noklusējuma `true`.
    ///   - season: Sezonas, pēc noklusējuma tukšs masīvs.
    ///   - size: Izmērs, pēc noklusējuma `0`.
    ///   - lastWorn: Pēdējoreiz vilkts, pēc noklusējuma `.now`.
    ///   - dirty: Netīrs, pēc noklusējuma `false`.
    ///   - washing: Mazgājas, pēc noklusējuma `false`.
    ///   - picture: Neobligāti foto dati, pēc noklusējuma `nil`.
    ///   - removeBackground: Noņemt fonu, pēc noklusējuma `false`.
    init(
        name: String = "Jauns Apģērbs",
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
    
    // MARK: - Attēla ielāde
    
    // Ielādē apģērba attēlu, noņemot fonu ja nepieciešams
    // Izmanto kešatmiņu, lai uzlabotu veiktspēju
    /// - Parameter completion: Pabeigšanas handler ar ielādēto UIImage.
    func loadImage(completion: @escaping (UIImage?) -> Void) {
        // Pārbauda, vai attēls ir kešatmiņā
        if let cachedImage = ClothingItem.imageCache.object(forKey: self.id.uuidString as NSString) {
            completion(cachedImage)
            return
        }

        // Asinhroni ielādē attēlu
        DispatchQueue.global(qos: .background).async {
            var image: UIImage?

            if let imageData = self.picture, let uiImage = UIImage(data: imageData) {
                if self.removeBackground {
                    image = self.removeBackground(from: uiImage) // Palīgfunkcija fona noņemšanai
                } else {
                    image = uiImage
                }
            }

            // Ievieto attēlu kešatmiņā, ja tas pieejams
            if let imageToCache = image {
                ClothingItem.imageCache.setObject(imageToCache, forKey: self.id.uuidString as NSString)
            }

            // Atgriež attēlu uz galvenās takts
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
    
    // Pārlādē attēlu, izņemot to no cache un pārlādējot
    func reloadImage() {
        // Izņemt attēlu no kešatmiņas
        ClothingItem.imageCache.removeObject(forKey: self.id.uuidString as NSString)
        
        // Pārlādē un atkal ievieto kešatmiņā attēlu
        loadImage { _ in }
    }
    
    // MARK: - Fona noņemšanas funkcijas
    
    // Noņem fonu no attēla izmantojot Vision un CoreImage
    /// - Parameter image: Oriģinālais UIImage attēls no kura noņemt fonu.
    /// - Returns: Jauns UIImage ar noņemtu fonu vai oriģinālais attēls, ja noņemšana neizdodas.
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

    // Izveido attēla masku izmantojot Vision.
    /// - Parameter inputImage: CIImage attēls ko apstrādāt.
    /// - Returns: CIImage maska vai nil, ja izveidošana neizdodas.
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

    // Pievieno masku oriģinālajam attēlam, lai noņemtu fonu.
    /// - Parameters:
    ///   - mask: CIImage maska, ko pievienot.
    ///   - image: Oriģinālais CIImage attēls.
    /// - Returns: Jauns CIImage attēls ar noņemtu fonu.
    private func applyMask(mask: CIImage, to image: CIImage) -> CIImage {
        let filter = CIFilter.blendWithMask()
        filter.inputImage = image
        filter.maskImage = mask
        filter.backgroundImage = CIImage.empty()
        return filter.outputImage!
    }

    // Pārvērš CIImage atpakaļ uz UIImage ar oriģinālu orientāciju.
    /// - Parameters:
    ///   - ciImage: CIImage attēls ko pārvērst.
    ///   - originalOrientation: Oriģinālā UIImage attēla orientācija.
    /// - Returns: Jauns UIImage attēls izveidots no CIImage.
    private func convertToUIImage(ciImage: CIImage, originalOrientation: UIImage.Orientation = .up) -> UIImage? {
        guard let cgImage = CIContext(options: nil).createCGImage(ciImage, from: ciImage.extent) else {
            print("Failed to render CGImage")
            return nil
        }
        return UIImage(cgImage: cgImage, scale: 1.0, orientation: originalOrientation)
    }
    
    // MARK: - Nodrošina atbilstību Hashable & Equatable pareizām relācijām u.c funkcionalitātei
    
    static func == (lhs: ClothingItem, rhs: ClothingItem) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: - Nodrošina atbilstību Codable
    
    // Definē atslēgas, iekļaujot relācijas
    enum CodingKeys: String, CodingKey {
        case id, name, notes, color, status, ironable, size, season, lastWorn, washing, dirty, picture, removeBackground, clothingItemDays
    }
    
    // Inicializē apģērbu no Decoder(atkodē uz lietojamām vērtībām), izņemot relācijas
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
    
    // Iekodē apģērbu, iekļaujot relācijas
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

// MARK: - Day Modelis

// Kalendāra diena
@Model
class Day: Codable {
    // MARK: - Atribūti
    
    @Attribute var id: UUID = UUID() // ID
    @Attribute var date: Date // Datums
    @Attribute var notes: String // Piezīmes
    
    // MARK: - Relācijas
    
    @Relationship var dayClothingItems: [ClothingItem] = [] // Dienai piesaistītie apģērbi
    
    // MARK: - Initializer
    
    // Inicializē dienu ar specifiskiem parametriem
    /// - Parameters:
    ///   - date: datums.
    ///   - notes: piezīmes.
    ///   - clothingItems: dienai piesaistītie apģērbi, pēc noklusējuma tukšs masīvs.
    init(date: Date, notes: String, clothingItems: [ClothingItem] = []) {
        self.date = date
        self.notes = notes
        self.dayClothingItems = clothingItems
    }
    
    // MARK: - Coding atbilstība
    
    // Definē atslēgas.
    enum CodingKeys: String, CodingKey {
        case id, date, notes, dayClothingItems
    }
    
    // Inicializē dienu no Decoder(atkodē lai var izmantot datus), izņemot relācijas.
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.date = try container.decode(Date.self, forKey: .date)
        self.notes = try container.decode(String.self, forKey: .notes)
        self.dayClothingItems = []
    }
    
    // Kodē dienu, ieskaitot relācijas
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(notes, forKey: .notes)
        try container.encode(dayClothingItems, forKey: .dayClothingItems)
    }
}


