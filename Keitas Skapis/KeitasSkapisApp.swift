import SwiftUI
import SwiftData

// MARK: - Ieejas punkts lietotnē
@main
struct KeitasSkapisApp: App {
    // Pārvalda izvēlētos apģērbus
    @StateObject private var chosenManager = ChosenManager()
    
    var body: some Scene {
        WindowGroup {
            // Galvenais skats pārvalda navigāciju starp visiem skatiem, ko nodrošina rīkjosla
            MainTabView()
                // Padod chosenManager skatiem, kuriem to vajag
                .environmentObject(chosenManager)
        }
        .modelContainer(for: [
            ClothingCategory.self,
            ClothingItem.self,
            Day.self
        ])
    }
}


