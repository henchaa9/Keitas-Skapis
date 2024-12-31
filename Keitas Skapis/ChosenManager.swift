//
//  ChosenManager.swift
//  Keitas Skapis
//
//  Created by Henrijs Obolevics on 27/12/2024.
//

import SwiftUI
import SwiftData

class ChosenManager: ObservableObject {
    @Published var chosenClothingItems: [ClothingItem] = []
    
    func add(_ clothingItem: ClothingItem) {
        // Avoid duplicates
        if !chosenClothingItems.contains(where: { $0.id == clothingItem.id }) {
            chosenClothingItems.append(clothingItem)
        }
    }

    func remove(_ clothingItem: ClothingItem) {
        chosenClothingItems.removeAll { $0.id == clothingItem.id }
    }

    func clear() {
        chosenClothingItems.removeAll()
    }
}
