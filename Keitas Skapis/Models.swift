//
//  Models.swift
//  Keitas Skapis
//
//  Created by Henrijs Obolevics on 06/10/2024.
//

import Foundation
import SwiftData
import SwiftUI

@Model
class Kategorija: Identifiable, Hashable {
    var nosaukums: String
    @Attribute(.externalStorage) var attels: Data?
    
    // Store `Apgerbs` relationships manually
    var apgerbi: [Apgerbs] = []
    
    init(nosaukums: String = "Jauna Kategorija", attels: Data? = nil) {
        self.nosaukums = nosaukums
        self.attels = attels
    }
    
    var image: UIImage? {
        get {
            guard let attels = attels else { return nil }
            return UIImage(data: attels)
        }
        set {
            attels = newValue?.pngData()
        }
    }
    
    static func == (lhs: Kategorija, rhs: Kategorija) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}


@Model
class Krasa {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double
    
    init(red: Double, green: Double, blue: Double, alpha: Double) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
    
    init(color: Color) {
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        self.red = Double(red)
        self.green = Double(green)
        self.blue = Double(blue)
        self.alpha = Double(alpha)
    }
    
    // Computed property to convert Krasa to SwiftUI Color
    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }
}


enum Sezona: String, CaseIterable, Codable {
    case vasara = "Vasara"
    case rudens = "Rudens"
    case ziema = "Ziema"
    case pavasaris = "Pavasaris"
}

@Model
class Apgerbs: Identifiable, Hashable {
    var nosaukums: String
    var piezimes: String
    var krasa: Krasa
    var stavoklis: Int
    var gludinams: Bool
    var izmers: Int
    var sezona: [Sezona]
    var pedejoreizVilkts: Date
    var mazgajas: Bool
    var netirs: Bool
    @Attribute(.externalStorage) var attels: Data?
    
    // Manually manage Kategorija relationships
    var kategorijas: [Kategorija] = []
    
    init(nosaukums: String = "Jauns Apgerbs", piezimes: String = "", krasa: Krasa, stavoklis: Int = 0, gludinams: Bool = true, sezona: [Sezona] = [], izmers: Int = 0, pedejoreizVilkts: Date = .now, netirs: Bool = false, mazgajas: Bool = false, attels: Data? = nil) {
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
    }
    
    var image: UIImage? {
        get {
            guard let attels = attels else { return nil }
            return UIImage(data: attels)
        }
        set {
            attels = newValue?.pngData()
        }
    }
    
    static func == (lhs: Apgerbs, rhs: Apgerbs) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}


@Model
class Diena {
    var datums: Date
    var piezimes: String
    
    var apgerbi: [Apgerbs] = []
    
    init(datums: Date, piezimes: String, apgerbi: [Apgerbs]) {
        self.datums = datums
        self.piezimes = piezimes
        self.apgerbi = apgerbi
    }
}

@Model
class Milakais {
    var nosaukums: String
    var piezimes: String
    
    var apgerbi: [Apgerbs] = []
    
    init(nosaukums: String, piezimes: String) {
        self.nosaukums = nosaukums
        self.piezimes = piezimes
    }
}

