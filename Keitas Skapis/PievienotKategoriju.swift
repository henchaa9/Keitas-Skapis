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

struct PievienotKategorijuView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext

    @State var categoryName = ""
    @State private var selectedImage: UIImage?
    @State private var isPickerPresented = false
    @State private var sourceType: UIImagePickerController.SourceType?

    @State private var showingOption = false
    @State private var removeBackground = false // User preference for background removal
    var existingCategory: ClothingCategory?

    init(existingCategory: ClothingCategory? = nil) {
        self.existingCategory = existingCategory
        _categoryName = State(initialValue: existingCategory?.name ?? "")
        if let imageData = existingCategory?.picture {
            _selectedImage = State(initialValue: UIImage(data: imageData))
        }
        _removeBackground = State(initialValue: existingCategory?.removeBackground ?? false)
    }

    var displayedImage: UIImage? {
        if removeBackground, let selectedImage = selectedImage {
            return removeBackground(from: selectedImage)
        }
        return selectedImage
    }

    var body: some View {
        VStack {
            HStack {
                Text("Pievienot Kategoriju").font(.title).bold().shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "arrowshape.left.fill").font(.title).foregroundStyle(.black)
                }.navigationBarBackButtonHidden(true)
            }.padding().background(Color(.systemGray6)).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.black), lineWidth: 1)).padding(.horizontal, 10).shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)

            VStack(alignment: .leading) {
                Button(action: addPhoto) {
                    ZStack {
                        if let displayedImage = displayedImage {
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
                                    .foregroundStyle(Color(.systemGray6))
                                Image(systemName: "camera")
                                    .foregroundStyle(.black)
                                    .font(.title2)
                            }
                        }
                    }
                }
                .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                .confirmationDialog("Pievienot attēlu", isPresented: $showingOption) {
                    Button("Kamera") {
                        sourceType = .camera
                        isPickerPresented = true
                    }
                    Button("Galerija") {
                        sourceType = .photoLibrary
                        isPickerPresented = true
                    }
                    Button("Atcelt", role: .cancel) {}
                }
                .sheet(isPresented: $isPickerPresented) {
                    if let sourceType = sourceType {
                        ImagePicker(selectedImage: $selectedImage, sourceType: sourceType)
                    }
                }

                Toggle("Noņemt fonu", isOn: $removeBackground)
                    .padding(.top, 20)

                TextField("Nosaukums", text: $categoryName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.top, 20)
                    .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
            }
            .padding(.top, 50)
            .padding(.horizontal, 20)
            

            Spacer()

//            HStack {
//                Button(action: apstiprinat) {
//                    Text("Apstiprināt").bold()
//                }
//                Spacer()
//            }
//            .padding()
            
            Button {
                Save()
            } label: {
                Text("Apstiprināt")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.white)
                    .foregroundColor(.blue)
                    .cornerRadius(10)
            }.shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2).padding(.vertical, 15).padding(.horizontal, 20)
            
        }.preferredColorScheme(.light).hideKeyboardOnTap()
    }

    func addPhoto() {
        showingOption = true
    }

    func Save() {
        guard !categoryName.isEmpty else {
            print("Category name cannot be empty")
            return
        }

        Task {
            let imageData = selectedImage?.pngData()
            if let category = existingCategory {
                // Update existing Kategorija
                category.name = categoryName
                category.picture = imageData
                category.removeBackground = removeBackground
            } else {
                // Insert new Kategorija
                let newKategorija = ClothingCategory(
                    name: categoryName,
                    picture: imageData,
                    removeBackground: removeBackground
                )
                modelContext.insert(newKategorija)
            }

            // Save context to persist changes
            do {
                try modelContext.save()
            } catch {
                print("Failed to save category: \(error.localizedDescription)")
            }

            dismiss()
        }
    }


    // Background removal logic remains the same
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
        return convertToUIImage(ciImage: outputImage, originalOrientation: image.imageOrientation)
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

    private func convertToUIImage(ciImage: CIImage, originalOrientation: UIImage.Orientation = .up) -> UIImage {
        guard let cgImage = CIContext(options: nil).createCGImage(ciImage, from: ciImage.extent) else {
            fatalError("Failed to render CGImage")
        }
        return UIImage(cgImage: cgImage, scale: 1.0, orientation: originalOrientation)
    }
}

#Preview {
    PievienotKategorijuView()
}
