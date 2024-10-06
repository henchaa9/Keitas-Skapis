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
    var body: some Scene {
        WindowGroup {
            PievienotKategorijuView()
        }
        .modelContainer(for: [Kategorija.self, Apgerbs.self])
    }
}
