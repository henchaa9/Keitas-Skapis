//
//  HideKeyboard.swift
//  Keitas Skapis
//
//  Created by Henrijs Obolevics on 29/12/2024.
//

import SwiftUI

extension View {
    func hideKeyboardOnTap() -> some View {
        self.onTapGesture {
            hideKeyboard()
        }
    }
}

func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}

