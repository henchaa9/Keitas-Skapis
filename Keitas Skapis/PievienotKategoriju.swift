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
    @State private var removeBackground = false // User preference for background removal
    @State private var backgroundRemovedImage: UIImage? // Stores the image with background removed
    
    var existingKategorija: Kategorija?
    
    init(existingKategorija: Kategorija? = nil) {
        self.existingKategorija = existingKategorija
        _kategorijasNosaukums = State(initialValue: existingKategorija?.nosaukums ?? "")
        if let imageData = existingKategorija?.attels {
            _selectedImage = State(initialValue: UIImage(data: imageData))
        }
    }
    
    // Computed property to show the correct image
    var displayedImage: UIImage? {
        if removeBackground, let backgroundRemovedImage = backgroundRemovedImage {
            return backgroundRemovedImage
        }
        return selectedImage
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
        VStack {
            HStack {
                Text("Pievienot Kategoriju").font(.title).bold()
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "arrowshape.left.fill").font(.title).foregroundStyle(.black)
                }.navigationBarBackButtonHidden(true)
            }
            .padding()
            
            VStack(alignment: .leading) {
                Button(action: pievienotFoto) {
                    ZStack {
                        if let displayedImage = displayedImage {
                            // Display the image based on the toggle
                            Image(uiImage: displayedImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 90, height: 120)
                                .clipped()
                        } else {
                            ZStack {
                                Image(systemName: "rectangle.portrait.fill")
                                    .resizable()
                                    .frame(width: 90, height: 120)
                                    .foregroundStyle(.gray)
                                    .opacity(0.50)
                                Image(systemName: "camera")
                                    .foregroundStyle(.black)
                                    .font(.title2)
                            }
                        }
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
                .sheet(isPresented: $isPickerPresented) {
                    if let sourceType = sourceType {
                        ImagePicker(selectedImage: $selectedImage, sourceType: sourceType)
                    }
                }
                
                Toggle("Remove Background", isOn: $removeBackground)
                    .padding(.top, 20)
                    .onChange(of: removeBackground) { _, newValue in
                        if newValue {
                            if let selectedImage = selectedImage {
                                backgroundRemovedImage = removeBackground(from: selectedImage)
                            }
                        }
                    }
                
                TextField("Nosaukums", text: $kategorijasNosaukums)
                    .textFieldStyle(.roundedBorder)
                    .padding(.top, 20)
            }
            .padding(.top, 50)
            .padding(.horizontal, 20)
            
            Spacer()
            
            HStack {
                Button(action: apstiprinat) {
                    Text("Apstiprināt").bold()
                }
                Spacer()
            }
            .padding()
        }
        .preferredColorScheme(.light)
        .background(Image("wardrobe_background")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .blur(radius: 5)
            .edgesIgnoringSafeArea(.all))
    }
    
    // Background removal logic
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
    
    private func convertToUIImage(ciImage: CIImage, originalOrientation: UIImage.Orientation = .up) -> UIImage {
        guard let cgImage = CIContext(options: nil).createCGImage(ciImage, from: ciImage.extent) else {
            fatalError("Failed to render CGImage")
        }
        
        // Create the UIImage with the original orientation
        return UIImage(cgImage: cgImage, scale: 1.0, orientation: originalOrientation)
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
        
        // Convert the processed CIImage to UIImage while preserving the original orientation
        return convertToUIImage(ciImage: outputImage, originalOrientation: image.imageOrientation)
    }

    
    func pievienotFoto() {
        showingOption = true
    }
    
    func apstiprinat() {
        guard let finalImage = displayedImage else {
            print("No image selected")
            return
        }
        
        Task {
            let processedImageData = finalImage.pngData()
            if let kategorija = existingKategorija {
                kategorija.nosaukums = kategorijasNosaukums
                kategorija.attels = processedImageData
            } else {
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
