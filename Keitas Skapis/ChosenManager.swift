
import SwiftUI
import SwiftData

// Klase, kas kontrolē izvēlētos apģērbus un saisītās funkcijas
/// Klase atbilst `ObservableObject` lai ļautu SwiftUI skatiem reaģēt uz izmaiņām.
class ChosenManager: ObservableObject {
    // MARK: - Publicētie (globālie) parametri
    
    // Masīvs, kas glabā izvēlētos apģērbus
    // Par izmaiņām masīvā tiks 'informēti' visi skati, kas to izmanto
    @Published var chosenClothingItems: [ClothingItem] = []
    
    // MARK: - Metodes
    
    /// Pievieno apģērbu masīvam
    /// - Parameter clothingItem: Apģērbs, kuru pievienot.
    /// - Note: Šī metode novērš dublikātus izmantojot to `id`.
    func add(_ clothingItem: ClothingItem) {
        // Novērš dublikātus
        if !chosenClothingItems.contains(where: { $0.id == clothingItem.id }) {
            chosenClothingItems.append(clothingItem)
        }
    }

    // Izņem apģērbu no izvēlēto masīva
    /// - Parameter clothingItem: Apģērbs.
    /// - Note: Tiek izmantots apģērba `id`, lai izņemtu pareizo apģērbu.
    func remove(_ clothingItem: ClothingItem) {
        chosenClothingItems.removeAll { $0.id == clothingItem.id }
    }

    // Izņem visus apģērbus no izvēlēto masīva.
    func clear() {
        chosenClothingItems.removeAll()
    }
}
