//
//  KeitasSkapisApp.swift
//  Keitas Skapis
//
//  Created by Henrijs Obolevics on 31/08/2024.
//

import SwiftUI
import SwiftData

@main
struct KeitasSkapisApp: App {
    @StateObject private var chosenManager = ChosenManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(chosenManager)
        }
        .modelContainer(for: [
            ClothingCategory.self,
            ClothingItem.self,
            Day.self
        ])
    }
}
