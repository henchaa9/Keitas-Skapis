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
class Kategorija {
    var nosaukums: String
    //@Attribute(.externalStorage) var attels: Data?
    
    var apgerbi: [Apgerbs] = []
    
    init(nosaukums: String = "Jauna Kategorija") {
        self.nosaukums = nosaukums
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
}

@Model
class Apgerbs {
    var nosaukums: String
    var piezimes: String
    var krasa: Krasa
    var stavoklis: Int
    var gludinams: Bool
    var izmers: Int
    var sezona: [String] = []
    var pedejoreizVilkts: Date
    var mazgajas: Bool
    var netirs: Bool
    //@Attribute(.externalStorage) var attels: Data?
    
    var kategorijas: [Kategorija] = []
    var dienas: [Diena] = []
    
    init(nosaukums: String = "jauns apgerbs", piezimes: String = "", krasa: Krasa, stavoklis: Int = 0, gludinams: Bool = true, izmers: Int = 0, pedejoreizVilkts: Date = .now, netirs: Bool = false, mazgajas: Bool = false) {
        self.nosaukums = nosaukums
        self.piezimes = piezimes
        self.krasa = krasa
        self.stavoklis = stavoklis
        self.gludinams = gludinams
        self.izmers = izmers
        self.pedejoreizVilkts = pedejoreizVilkts
        self.mazgajas = mazgajas
        self.netirs = netirs
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

