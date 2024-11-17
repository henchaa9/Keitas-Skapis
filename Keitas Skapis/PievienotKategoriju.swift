//
//  PievienotKategoriju.swift
//  Keitas Skapis
//
//  Created by Henrijs Obolevics on 06/10/2024.
//

import SwiftUI
import SwiftData
import UIKit
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

struct PievienotKategorijuView: View {
    // Environment properties
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    // State for the category name and image
    @State var kategorijasNosaukums = ""
    @State private var selectedImage: UIImage?
    @State private var isPickerPresented = false
    @State private var sourceType: UIImagePickerController.SourceType?
    @State private var showingOption = false

    // Passed Apgerbs to add to this Kategorija
    private var apgerbiToAdd: [Apgerbs]

    // For editing an existing Kategorija
    var existingKategorija: Kategorija?

    // Custom initializer
    init(existingKategorija: Kategorija? = nil, apgerbiToAdd: [Apgerbs] = []) {
        self.existingKategorija = existingKategorija
        self.apgerbiToAdd = apgerbiToAdd
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

             func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
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
        VStack {
            // Header with title and dismiss button
            HStack {
                Text(existingKategorija == nil ? "Pievienot Kategoriju" : "Labot Kategoriju")
                    .font(.title)
                    .bold()
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "arrowshape.left.fill")
                        .font(.title)
                        .foregroundStyle(.black)
                }
                .navigationBarBackButtonHidden(true)
            }
            .padding()

            // Image picker and category name input
            VStack(alignment: .leading) {
                // Button to add a photo
                Button(action: pievienotFoto) {
                    ZStack {
                        Image(systemName: "rectangle.portrait.fill")
                            .resizable()
                            .frame(width: 60, height: 90)
                            .foregroundStyle(.gray)
                            .opacity(0.50)
                        Image(systemName: "camera")
                            .foregroundStyle(.black)
                            .font(.title2)
                    }
                }
                .confirmationDialog("Change background", isPresented: $showingOption) {
                    Button("Camera") {
                        sourceType = .camera
                        isPickerPresented = true
                    }
                    Button("Photo Library") {
                        sourceType = .photoLibrary
                        isPickerPresented = true
                    }
                    Button("Cancel", role: .cancel) {}
                }
                
                // TextField for the category name
                TextField("Nosaukums", text: $kategorijasNosaukums)
                    .textFieldStyle(.roundedBorder)
                    .padding(.top, 20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 50)

            Spacer()

            // Save button
            HStack {
                Button(action: apstiprinat) {
                    Text("Apstiprināt")
                        .bold()
                }
                Spacer()
            }
            .padding()
        }
        .preferredColorScheme(.light)
        .sheet(isPresented: $isPickerPresented) {
            if let sourceType = sourceType {
                ImagePicker(selectedImage: $selectedImage, sourceType: sourceType)
            }
        }
    }
    
    // MARK: - Image Picker and Photo Actions

    func pievienotFoto() {
        showingOption = true
    }
    
    // MARK: - Save or Update the Category

    func apstiprinat() {
        Task {
            let processedImageData: Data?

            if let selectedImage = selectedImage {
                // Process the new image (optional background removal)
                let backgroundlessImage = removeBackground(from: selectedImage)
                processedImageData = backgroundlessImage.pngData()
            } else {
                processedImageData = nil
            }
            
            if let kategorija = existingKategorija {
                // Update existing Kategorija
                kategorija.nosaukums = kategorijasNosaukums
                kategorija.attels = processedImageData
            } else {
                // Create a new Kategorija
                let newKategorija = Kategorija(nosaukums: kategorijasNosaukums, attels: processedImageData)
                newKategorija.apgerbi.append(contentsOf: apgerbiToAdd) // Add passed Apgerbs
                modelContext.insert(newKategorija)
            }

            dismiss()
        }
    }
    
    // MARK: - Image Processing Functions

    private func removeBackground(from image: UIImage) -> UIImage {
        guard let inputImage = CIImage(image: image) else {
            print("Failed to create CIImage")
            return image
        }

        guard let maskImage = createMask(from: inputImage) else {
            print("Failed to create mask")
            return image
        }

        let outputImage = applyMask(mask: maskImage, to: inputImage)
        return convertToUIImage(ciImage: outputImage)
    }

    private func createMask(from inputImage: CIImage) -> CIImage? {
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(ciImage: inputImage)

        do {
            try handler.perform([request])
            if let result = request.results?.first {
                let mask = try result.generateScaledMaskForImage(forInstances: result.allInstances, from: handler)
                return CIImage(cvPixelBuffer: mask)
            }
        } catch {
            print(error)
        }

        return nil
    }

    private func applyMask(mask: CIImage, to image: CIImage) -> CIImage {
        let filter = CIFilter.blendWithMask()
        filter.inputImage = image
        filter.maskImage = mask
        filter.backgroundImage = CIImage.empty()
        return filter.outputImage!
    }

    private func convertToUIImage(ciImage: CIImage) -> UIImage {
        guard let cgImage = CIContext(options: nil).createCGImage(ciImage, from: ciImage.extent) else {
            fatalError("Failed to render CGImage")
        }
        return UIImage(cgImage: cgImage)
    }
}

#Preview {
    PievienotKategorijuView()
}


