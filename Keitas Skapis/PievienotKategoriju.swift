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
    
    // nakamas 4 funkcijas ir prieks background removal
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
    
    private func removeBackground(from image: UIImage) -> UIImage {
        guard let inputImage = CIImage(image: image) else {
            print("Failed to create CIImage")
            return image
        }
        
        // Background removal logic
        guard let maskImage = createMask(from: inputImage) else {
            print("Failed to create mask")
            return image
        }
        
        let outputImage = applyMask(mask: maskImage, to: inputImage)
        let finalImage = convertToUIImage(ciImage: outputImage)
        
        // Rotate the final image 90 degrees clockwise
        return rotateImageClockwise(finalImage)
    }

    
    private func rotateImageClockwise(_ image: UIImage) -> UIImage {
        UIGraphicsBeginImageContext(CGSize(width: image.size.height, height: image.size.width))
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return image
        }
        
        // Move origin to the center of the image
        context.translateBy(x: image.size.height / 2, y: image.size.width / 2)
        // Rotate context 90 degrees clockwise
        context.rotate(by: .pi / 2)
        // Draw the image at the new orientation
        image.draw(in: CGRect(x: -image.size.width / 2, y: -image.size.height / 2, width: image.size.width, height: image.size.height))
        
        let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return rotatedImage ?? image
    }

    //
    
    func pievienotFoto () {
        showingOption = true
    }
    
    func apstiprinat() {
        guard let selectedImage = selectedImage else {
            print("No image selected")
            return
        }
        
        Task {
            // Remove background from the selected image
            let backgroundlessImage = removeBackground(from: selectedImage)
            
            // Convert the processed image to Data
            let processedImageData = backgroundlessImage.pngData()
            
            if let kategorija = existingKategorija {
                // Update existing category
                kategorija.nosaukums = kategorijasNosaukums
                kategorija.attels = processedImageData // Save processed image
            } else {
                // Create new category with processed image
                let newKategorija = Kategorija(nosaukums: kategorijasNosaukums, attels: processedImageData)
                modelContext.insert(newKategorija)
            }
            
            dismiss()
        }
    }

}

#Preview {
    PievienotKategorijuView()
}
