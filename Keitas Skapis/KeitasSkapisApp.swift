
import SwiftUI
import SwiftData

// Ieejas punkts programmā
@main
struct KeitasSkapisApp: App {
    // Mainīgais, kas globāli pārvalda lietotāja izvēlētos apģērbus
    @StateObject private var chosenManager = ChosenManager()
    
    var body: some Scene {
        WindowGroup {
            // Galvenais skats
            ContentView()
                .environmentObject(chosenManager)
        }
        .modelContainer(for: [
            // Galvenie datu modeļi
            ClothingCategory.self,
            ClothingItem.self,
            Day.self,
        ])
    }
}


