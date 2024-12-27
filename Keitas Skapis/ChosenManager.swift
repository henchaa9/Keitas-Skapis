//
//  ChosenManager.swift
//  Keitas Skapis
//
//  Created by Henrijs Obolevics on 27/12/2024.
//

import SwiftUI
import SwiftData

class ChosenManager: ObservableObject {
    @Published var chosenApgerbi: [Apgerbs] = []
    
    func add(_ apgerbs: Apgerbs) {
        // Avoid duplicates
        if !chosenApgerbi.contains(where: { $0.id == apgerbs.id }) {
            chosenApgerbi.append(apgerbs)
        }
    }

    func remove(_ apgerbs: Apgerbs) {
        chosenApgerbi.removeAll { $0.id == apgerbs.id }
    }

    func clear() {
        chosenApgerbi.removeAll()
    }
}
