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

// MARK: - ImagePicker

/// A UIViewControllerRepresentable struct that wraps UIImagePickerController for use in SwiftUI.
struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) private var presentationMode
    @Binding var selectedImage: UIImage?
    var sourceType: UIImagePickerController.SourceType

    /// Creates and configures the UIImagePickerController.
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }

    /// Updates the UIImagePickerController (not used here).
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    /// Creates the Coordinator instance to handle UIImagePickerControllerDelegate methods.
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    /// Coordinator class to manage UIImagePickerController interactions.
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        /// Handles the image selection and dismisses the picker.
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        /// Handles cancellation and dismisses the picker.
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - PievienotKategorijuView

/// A SwiftUI view for adding or editing a clothing category, including name and image with optional background removal.
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

    /// Initializes the view with an optional existing category for editing.
    init(existingCategory: ClothingCategory? = nil) {
        self.existingCategory = existingCategory
        _categoryName = State(initialValue: existingCategory?.name ?? "")
        if let imageData = existingCategory?.picture {
            _selectedImage = State(initialValue: UIImage(data: imageData))
        }
        _removeBackground = State(initialValue: existingCategory?.removeBackground ?? false)
    }

    /// Computes the displayed image, applying background removal if enabled.
    var displayedImage: UIImage? {
        if removeBackground, let selectedImage = selectedImage {
            return removeBackground(from: selectedImage)
        }
        return selectedImage
    }

    var body: some View {
        VStack {
            // Header with title and close button
            HStack {
                Text("Pievienot Kategoriju")
                    .font(.title)
                    .bold()
                    .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "arrowshape.left.fill")
                        .font(.title)
                        .foregroundStyle(.black)
                }
                .navigationBarBackButtonHidden(true)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.black), lineWidth: 1))
            .padding(.horizontal, 10)
            .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)

            // Content for adding image, toggle, and name
            VStack(alignment: .leading) {
                // Button to add or change the category image
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
                // Confirmation dialog for image source selection
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
                // Presents the ImagePicker sheet
                .sheet(isPresented: $isPickerPresented) {
                    if let sourceType = sourceType {
                        ImagePicker(selectedImage: $selectedImage, sourceType: sourceType)
                    }
                }

                // Toggle for background removal
                Toggle("Noņemt fonu", isOn: $removeBackground)
                    .padding(.top, 20)

                // Text field for entering the category name
                TextField("Nosaukums", text: $categoryName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.top, 20)
                    .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
            }
            .padding(.top, 50)
            .padding(.horizontal, 20)

            Spacer()

            // Confirmation button to save the category
            Button {
                Save() // Helper Function
            } label: {
                Text("Apstiprināt")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.white)
                    .foregroundColor(.blue)
                    .cornerRadius(10)
            }
            .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
            .padding(.vertical, 15)
            .padding(.horizontal, 20)
        }
        .preferredColorScheme(.light)
        .hideKeyboardOnTap()
    }

    // MARK: - Actions

    /// Presents the confirmation dialog for selecting an image source.
    func addPhoto() {
        showingOption = true
    }

    /// Saves the new or updated clothing category to the data model.
    private func Save() {
        // Ensure the category name is not empty
        guard !categoryName.isEmpty else {
            print("Category name cannot be empty")
            return
        }

        Task {
            let imageData = selectedImage?.pngData()
            if let category = existingCategory {
                // Update existing category
                category.name = categoryName
                category.picture = imageData
                category.removeBackground = removeBackground
            } else {
                // Insert new category
                let newKategorija = ClothingCategory(
                    name: categoryName,
                    picture: imageData,
                    removeBackground: removeBackground
                )
                modelContext.insert(newKategorija)
            }

            // Attempt to save the context to persist changes
            do {
                try modelContext.save()
            } catch {
                print("Failed to save category: \(error.localizedDescription)")
            }

            dismiss() // Close the view after saving
        }
    }

    // MARK: - Helper Functions

    /// Removes the background from the provided image using Vision and CoreImage.
    /// - Parameter image: The original UIImage from which to remove the background.
    /// - Returns: A new UIImage with the background removed, or the original image if removal fails.
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

    /// Creates a mask image using Vision's foreground instance mask request.
    /// - Parameter inputImage: The CIImage to process.
    /// - Returns: A CIImage mask or nil if creation fails.
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

    /// Applies the mask to the original image to remove the background.
    /// - Parameters:
    ///   - mask: The CIImage mask to apply.
    ///   - image: The original CIImage.
    /// - Returns: A new CIImage with the background removed.
    private func applyMask(mask: CIImage, to image: CIImage) -> CIImage {
        let filter = CIFilter.blendWithMask()
        filter.inputImage = image
        filter.maskImage = mask
        filter.backgroundImage = CIImage.empty()
        return filter.outputImage!
    }

    /// Converts a CIImage back to a UIImage with the original orientation.
    /// - Parameters:
    ///   - ciImage: The CIImage to convert.
    ///   - originalOrientation: The original orientation of the UIImage.
    /// - Returns: A new UIImage created from the CIImage.
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
