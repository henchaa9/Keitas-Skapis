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
                Text("Apstiprinat")
            }
            Spacer()
        }.padding()
        
//        VStack {
//             // Display the selected image
//             if let image = selectedImage {
//                 Image(uiImage: image)
//                     .resizable()
//                     .scaledToFit()
//                     .frame(width: 200, height: 200)
//             } else {
//                 Text("Select an Image")
//                     .font(.headline)
//             }
//
//             // Buttons to pick image or take photo
//             HStack {
//                 Button("Pick from Gallery") {
//                     sourceType = .photoLibrary
//                     DispatchQueue.main.async {
//                         isPickerPresented = true
//                     }
//                 }
//
//                 Button("Take Photo") {
//                     sourceType = .camera
//                     DispatchQueue.main.async {
//                         isPickerPresented = true
//                     }
//                 }
//            }
//         }
//        .sheet(isPresented: $isPickerPresented) {
//            if let sourceType = sourceType {
//                ImagePicker(selectedImage: $selectedImage, sourceType: sourceType)
//            }
//        }
    }
    
    func pievienotFoto () {
        showingOption = true
    }
    
    func apstiprinat() {
        let imageData = selectedImage?.pngData()
        
        let jaunaKategorija = Kategorija(nosaukums: kategorijasNosaukums, attels: imageData)
        
        modelContext.insert(jaunaKategorija)
        try? modelContext.save()
        
        dismiss()
    }
}

#Preview {
    PievienotKategorijuView()
}
