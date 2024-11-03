//
//  PievienotKategoriju.swift
//  Keitas Skapis
//
//  Created by Henrijs Obolevics on 06/10/2024.
//

import SwiftUI
import SwiftData
import UIKit

struct PievienotKategorijuView: View {
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    @State var kategorijasNosaukums = ""
    
    @State private var selectedImage: UIImage?
    @State private var isPickerPresented = false
    @State private var sourceType: UIImagePickerController.SourceType?
    
    @State private var showingOption = false
    
    var existingKategorija: Kategorija?
    
    init(existingKategorija: Kategorija? = nil) {
        self.existingKategorija = existingKategorija
        _kategorijasNosaukums = State(initialValue: existingKategorija?.nosaukums ?? "")
        if let imageData = existingKategorija?.attels {
            _selectedImage = State(initialValue: UIImage(data: imageData))
        }
    }
    
    struct ImagePicker: UIViewControllerRepresentable {
        @Environment(\.presentationMode) private var presentationMode
        @Binding var selectedImage: UIImage?
        var sourceType: UIImagePickerController.SourceType

        func makeUIViewController(context: Context) -> UIImagePickerController {
            let picker = UIImagePickerController()
            picker.delegate = context.coordinator
            picker.sourceType = sourceType
            return picker
        }

        func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }

        class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
            let parent: ImagePicker

            init(_ parent: ImagePicker) {
                self.parent = parent
            }

            func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
                if let image = info[.originalImage] as? UIImage {
                    parent.selectedImage = image
                }
                parent.presentationMode.wrappedValue.dismiss()
            }
            
            func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
                parent.presentationMode.wrappedValue.dismiss()
            }
        }
    }

    
    var body: some View {
        HStack {
            Text("Pievienot Kategoriju").font(.title).bold()
            
            Spacer()
            
            Button(action: {dismiss()}) {
                Image(systemName: "arrowshape.left.fill").font(.title).foregroundStyle(.black)
            }.navigationBarBackButtonHidden(true)
        }.padding().preferredColorScheme(.light)
        
        VStack (alignment: .leading) {
            Button (action: pievienotFoto) {
                ZStack {
                    Image(systemName: "rectangle.portrait.fill").resizable().frame(width: 60, height: 90).foregroundStyle(.gray).opacity(0.50)
                    Image(systemName: "camera").foregroundStyle(.black).font(.title2)
                }
            }.confirmationDialog("Change background", isPresented: $showingOption) {
                Button("Camera") {
                    sourceType = .camera
                    isPickerPresented = true
                }
                Button("Photo Library") {
                    sourceType = .photoLibrary
                    isPickerPresented = true
                }
                Button("Cancel", role: .cancel) { }
            }
            TextField("Nosaukums", text: $kategorijasNosaukums).textFieldStyle(.roundedBorder).padding(.top, 20)
        }.padding(.top, 50).padding(.horizontal, 20)
            .sheet(isPresented: $isPickerPresented) {
                    if let sourceType = sourceType {
                        ImagePicker(selectedImage: $selectedImage, sourceType: sourceType)
                    }
                }
        
        Spacer()
        
        HStack {
            Button (action: apstiprinat) {
                Text("Apstiprināt").bold()
            }
            Spacer()
        }.padding()
    }
    
    func pievienotFoto () {
        showingOption = true
    }
    
    func apstiprinat() {
        if let kategorija = existingKategorija {
            // Update existing category
            kategorija.nosaukums = kategorijasNosaukums
            if let image = selectedImage?.pngData() {
                kategorija.attels = image
            }
        } else {
            // Create new category
            let newKategorija = Kategorija(nosaukums: kategorijasNosaukums, attels: selectedImage?.pngData())
            modelContext.insert(newKategorija)
        }
        
        dismiss()
    }
}

#Preview {
    PievienotKategorijuView()
}
