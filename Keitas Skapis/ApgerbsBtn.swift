//
//  ApgerbsBtn.swift
//  Keitas Skapis
//
//  Created by Henrijs Obolevics on 14/12/2024.
//

import SwiftUI

struct ApgerbsButton: View {
    let apgerbs: Apgerbs
    let isSelected: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void

    var body: some View {
        VStack {
            AsyncImageView(apgerbs: apgerbs)
                .frame(width: 80, height: 80)
                .padding(.top, 5)
                .padding(.bottom, -10)

            Text(apgerbs.nosaukums)
                .frame(width: 80, height: 30)
        }
        .frame(width: 90, height: 120)
        .background(isSelected ? Color.blue.opacity(0.3) : Color(.systemGray6))
        .cornerRadius(8)
        .contentShape(Rectangle()) // Ensures the entire frame is tappable
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture {
            onLongPress()
        }
    }
}

