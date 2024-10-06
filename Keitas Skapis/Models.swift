//
//  Models.swift
//  Keitas Skapis
//
//  Created by Henrijs Obolevics on 06/10/2024.
//

import Foundation
import SwiftData

@Model
class Kategorija {
    var id: UUID = UUID()
    var nosaukums: String
    //@Attribute(.externalStorage) var attels: Data?
    
    var apgerbi: [Apgerbs] = []
    
    init(nosaukums: String = "jauna kategorija") {
        self.nosaukums = nosaukums
    }
}

@Model
class Apgerbs {
    var id: UUID = UUID()
    var nosaukums: String
    var piezimes: String
    var krasa: String
    var gludinams: Bool
    var izmers: String
    var sezona: [String] = []
    var pedejoreizVilkts: Date
    //@Attribute(.externalStorage) var attels: Data?
    
    var kategorijas: [Kategorija] = []
    var dienas: [Diena] = []
    
    init(nosaukums: String = "jauns apgerbs", piezimes: String = "", krasa: String = "", gludinams: Bool = true, izmers: String = "", pedejoreizVilkts: Date = .now) {
        self.nosaukums = nosaukums
        self.piezimes = piezimes
        self.krasa = krasa
        self.gludinams = gludinams
        self.izmers = izmers
        self.pedejoreizVilkts = pedejoreizVilkts
    }
}

@Model
class Diena {
    var id: UUID = UUID()
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
    var id: UUID = UUID()
    var nosaukums: String
    var piezimes: String
    
    var apgerbi: [Apgerbs] = []
    
    init(nosaukums: String, piezimes: String) {
        self.nosaukums = nosaukums
        self.piezimes = piezimes
    }
}

@Model
class Mazgasana {
    var apgerbi: [Apgerbs] = []
    
    init (apgerbi: [Apgerbs] = []) {
        self.apgerbi = apgerbi
    }
}

@Model
class Netirs {
    var apgerbi: [Apgerbs] = []
    
    init (apgerbi: [Apgerbs] = []) {
        self.apgerbi = apgerbi
    }
}
