//
//  ChosenManager.swift
//  Keitas Skapis
//
//  Created by Henrijs Obolevics on 27/12/2024.
//

import SwiftUI
import SwiftData

/// A manager class to handle operations for chosen clothing items.
/// This class conforms to `ObservableObject` to allow SwiftUI views to react to changes.
class ChosenManager: ObservableObject {
    // MARK: - Published Properties
    
    /// An array to store the currently chosen clothing items.
    /// Changes to this array will notify SwiftUI views observing this object.
    @Published var chosenClothingItems: [ClothingItem] = []
    
    // MARK: - Methods
    
    /// Adds a clothing item to the chosen list.
    /// - Parameter clothingItem: The `ClothingItem` to add.
    /// - Note: This method prevents duplicate items by checking their `id`.
    func add(_ clothingItem: ClothingItem) {
        // Avoid duplicates
        if !chosenClothingItems.contains(where: { $0.id == clothingItem.id }) {
            chosenClothingItems.append(clothingItem)
        }
    }

    /// Removes a clothing item from the chosen list.
    /// - Parameter clothingItem: The `ClothingItem` to remove.
    /// - Note: It matches the clothing item by `id` to ensure the correct item is removed.
    func remove(_ clothingItem: ClothingItem) {
        chosenClothingItems.removeAll { $0.id == clothingItem.id }
    }

    /// Clears all clothing items from the chosen list.
    /// - Note: This method removes all items, leaving the list empty.
    func clear() {
        chosenClothingItems.removeAll()
    }
}
