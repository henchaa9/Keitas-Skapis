
import SwiftUI

// Paplašinājums, kas atļauj lietotājam piespiest uz tukšuma, lai paslēptu tastatūru
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


