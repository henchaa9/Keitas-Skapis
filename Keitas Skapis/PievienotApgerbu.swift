//
//  PievienotApgerbu.swift
//  Keitas Skapis
//
//  Created by Henrijs Obolevics on 10/10/2024.
//

import SwiftUI
import SwiftData
import UIKit
import Vision

struct PievienotApgerbuView: View {
    
    // MARK: - Data Queries
    
    @Query private var categories: [ClothingCategory] // Fetches clothing categories
    @Query private var clothingItems: [ClothingItem] // Fetches clothing items
    
    // MARK: - Environment Variables
    
    @Environment(\.dismiss) var dismiss // Allows dismissing the view
    @Environment(\.modelContext) private var modelContext // Provides access to the data model context
    
    // MARK: - State Variables
    
    @State var clothingItemName = "" // Stores the name of the clothing item
    @State var clothingItemNotes = "" // Stores notes about the clothing item
    @State private var isExpandedCategories = false // Controls the expansion of categories section
    @State private var isExpandedSeason = false // Controls the expansion of season section
    @State var clothingItemCategories: Set<ClothingCategory> = [] // Selected categories for the clothing item
    @State var chosenColor: Color = .white // Selected color
    @State var clothingItemColor: CustomColor? // Custom color object based on chosenColor
    @State var clothingItemStatus = 0 // Status of the clothing item (e.g., clean, dirty)
    @State var clothingItemIronable = true // Indicates if the clothing item is ironable
    @State var clothingItemSize = 0 // Size of the clothing item
    let seasonChoise = [Season.summer, Season.fall, Season.winter, Season.spring] // Available seasons
    @State var clothingItemSeason: Set<Season> = [] // Selected seasons for the clothing item
    @State var clothingItemLastWorn = Date.now // Date when the clothing item was last worn
    @State private var selectedImage: UIImage? // Image selected by the user
    @State private var isPickerPresented = false // Controls the presentation of the image picker
    @State private var sourceType: UIImagePickerController.SourceType? // Source type for image picker (camera or photo library)
    @State private var showingOption = false // Controls the presentation of image source options
    @State private var removeBackground = false // User preference for background removal
    @State private var backgroundRemovedImage: UIImage? // Stores the image with background removed
    var existingClothingItem: ClothingItem? // Existing clothing item, if editing
    
    // MARK: - Computed Properties
    
    /// Determines which image to display based on the removeBackground toggle
    var displayedImage: UIImage? {
        if removeBackground {
            return backgroundRemovedImage ?? selectedImage
        }
        return selectedImage
    }

    // MARK: - Initialization
    
    /// Initializes the view with an existing clothing item if provided
    /// - Parameter existingClothingItem: The clothing item to edit, if any
    init(existingClothingItem: ClothingItem? = nil) {
        self.existingClothingItem = existingClothingItem
        if let item = existingClothingItem {
            _clothingItemName = State(initialValue: item.name)
            _clothingItemNotes = State(initialValue: item.notes)
            _clothingItemCategories = State(initialValue: Set(item.clothingItemCategories))
            _chosenColor = State(initialValue: item.color.color)
            _clothingItemStatus = State(initialValue: item.dirty ? 1 : (item.washing ? 2 : 0))
            _clothingItemIronable = State(initialValue: item.ironable)
            _clothingItemSize = State(initialValue: item.size)
            _clothingItemSeason = State(initialValue: Set(item.season))
            _clothingItemLastWorn = State(initialValue: item.lastWorn)
            _removeBackground = State(initialValue: item.removeBackground)

            // Load and process the image
            if let imageData = item.picture, let image = UIImage(data: imageData) {
                if item.removeBackground {
                    _selectedImage = State(initialValue: image)
                    _backgroundRemovedImage = State(initialValue: removeBackground(from: image)) // Uses helper function
                } else {
                    _selectedImage = State(initialValue: image)
                }
            }
        }
    }

    // MARK: - Image Picker
    
    /// A UIViewControllerRepresentable struct to handle image picking from camera or photo library
    struct ImagePicker: UIViewControllerRepresentable {
        @Environment(\.presentationMode) private var presentationMode // Controls presentation
        @Binding var selectedImage: UIImage? // Binds the selected image
        var sourceType: UIImagePickerController.SourceType // Source type for the picker

        /// Creates the UIImagePickerController
        func makeUIViewController(context: Context) -> UIImagePickerController {
            let picker = UIImagePickerController()
            picker.delegate = context.coordinator
            picker.sourceType = sourceType
            return picker
        }

        /// Updates the UIImagePickerController (not needed here)
        func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

        /// Creates the coordinator for handling picker delegate methods
        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }

        /// Coordinator class to handle UIImagePickerControllerDelegate methods
        class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
            let parent: ImagePicker

            init(_ parent: ImagePicker) {
                self.parent = parent
            }

            /// Handles image selection
            func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
                if let image = info[.originalImage] as? UIImage {
                    parent.selectedImage = image
                }
                parent.presentationMode.wrappedValue.dismiss()
            }
            
            /// Handles cancellation of image picker
            func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
                parent.presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    // MARK: - View Body
    
    var body: some View {
        VStack {
            // Header with title and back button
            HStack {
                Text("Pievienot Apģērbu")
                    .font(.title)
                    .bold()
                    .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                Spacer()
                Button(action: { dismiss() }) { // Button to dismiss the view
                    Image(systemName: "arrowshape.left.fill")
                        .font(.title)
                        .foregroundStyle(.black)
                        .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                }
                .navigationBarBackButtonHidden(true)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.black), lineWidth: 1))
            .padding(.horizontal, 10)
            .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
            
            Spacer()
            
            // Scrollable content
            ScrollView {
                VStack (alignment: .leading) {
                    // Image selection section
                    VStack (alignment: .leading) {
                        Button(action: addPhoto) { // Button to add photo
                            ZStack {
                                if let displayedImage = displayedImage {
                                    // Display the image dynamically based on the toggle
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
                        .confirmationDialog("Pievienot attēlu", isPresented: $showingOption) { // Dialog for image source selection
                            Button("Kamera") {
                                sourceType = .camera
                                isPickerPresented = true
                            }
                            Button("Galerija") {
                                sourceType = .photoLibrary
                                isPickerPresented = true
                            }
                            Button("Atcelt", role: .cancel) { }
                        }
                    }
                    .sheet(isPresented: $isPickerPresented) { // Presents the ImagePicker
                        if let sourceType = sourceType {
                            ImagePicker(selectedImage: $selectedImage, sourceType: sourceType)
                        }
                    }
                    
                    // Toggle for background removal
                    Toggle("Noņemt fonu", isOn: $removeBackground)
                        .padding(.top, 20)
                        .onChange(of: removeBackground) { _, newValue in
                            if newValue, let selectedImage = selectedImage {
                                backgroundRemovedImage = removeBackground(from: selectedImage) // Uses helper function
                            }
                        }

                    // Text fields for name and notes
                    TextField("Nosaukums", text: $clothingItemName)
                        .textFieldStyle(.roundedBorder)
                        .padding(.top, 20)
                        .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                    TextField("Piezīmes", text: $clothingItemNotes)
                        .textFieldStyle(.roundedBorder)
                        .padding(.top, 10)
                        .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                    
                    // Categories selection
                    VStack(alignment: .leading) {
                        Button(action: { isExpandedCategories.toggle() }) { // Toggle button for categories
                            HStack {
                                Text("Kategorijas")
                                    .foregroundStyle(.black)
                                Spacer()
                                Image(systemName: isExpandedCategories ? "chevron.up" : "chevron.down")
                                    .foregroundStyle(.black)
                            }
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                        }
                        
                        if isExpandedCategories {
                            VStack {
                                ForEach(categories, id: \.self) { category in // List of categories
                                    HStack {
                                        Text(category.name)
                                        Spacer()
                                        if clothingItemCategories.contains(category) {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                    .padding()
                                    .onTapGesture { // Toggle category selection
                                        if clothingItemCategories.contains(category) {
                                            clothingItemCategories.remove(category)
                                        } else {
                                            clothingItemCategories.insert(category)
                                        }
                                    }
                                }
                            }
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(radius: 5)
                        }
                    }
                    .padding(.top, 10)
                    
                    // Color picker
                    ColorPicker("Krāsa", selection: Binding(
                        get: { chosenColor },
                        set: { newColor in
                            chosenColor = newColor
                            clothingItemColor = CustomColor(color: newColor) // Updates custom color
                        }
                    ))
                    .padding(8)
                    
                    // Size picker
                    Picker("Izmērs", selection: $clothingItemSize) {
                        Text("XS").tag(0)
                        Text("S").tag(1)
                        Text("M").tag(2)
                        Text("L").tag(3)
                        Text("XL").tag(4)
                    }
                    .pickerStyle(.segmented)
                    .padding(.top, 10)
                    
                    // Status picker
                    Picker("Stāvoklis", selection: $clothingItemStatus) {
                        Text("Tīrs").tag(0)
                        Text("Netīrs").tag(1)
                        Text("Mazgājas").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.top, 10)
                    
                    // Season selection
                    VStack(alignment: .leading) {
                        Button(action: { isExpandedSeason.toggle() }) { // Toggle button for seasons
                            HStack {
                                Text("Sezona")
                                    .foregroundStyle(.black)
                                Spacer()
                                Image(systemName: isExpandedSeason ? "chevron.up" : "chevron.down")
                                    .foregroundStyle(.black)
                            }
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                        }
                        
                        if isExpandedSeason {
                            VStack {
                                ForEach(seasonChoise, id: \.self) { season in // List of seasons
                                    HStack {
                                        Text(season.rawValue)
                                        Spacer()
                                        if clothingItemSeason.contains(season) {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                    .padding()
                                    .onTapGesture { // Toggle season selection
                                        if clothingItemSeason.contains(season) {
                                            clothingItemSeason.remove(season)
                                        } else {
                                            clothingItemSeason.insert(season)
                                        }
                                    }
                                }
                            }
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(radius: 5)
                        }
                    }
                    .padding(.top, 10)
                    
                    // Date picker for last worn date
                    DatePicker("Pēdējoreiz vilkts", selection: $clothingItemLastWorn, displayedComponents: [.date])
                        .padding(.top, 15)
                        .padding(.horizontal, 5)
                    
                    // Toggle for ironable
                    Toggle(isOn: $clothingItemIronable) {
                        Text("Gludināms")
                    }
                    .padding(.top, 15)
                    .padding(.horizontal, 5)
                    
                    // Confirmation button
                    Button {
                        Confirm() // Calls the Confirm function
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
                    .padding(.horizontal, 5)
                    
                }
                .padding(20)
            }
        }
        .preferredColorScheme(.light) // Sets the color scheme to light
        .hideKeyboardOnTap() // Hides the keyboard when tapping outside
    }
    
    // MARK: - Helper Functions
    
    /// Removes the background from the given image using Vision framework.
    /// - Parameter image: The original UIImage.
    /// - Returns: A new UIImage with the background removed.
    /// - Note: This function is used in the initializer and when the removeBackground toggle changes.
    private func removeBackground(from image: UIImage) -> UIImage {
        guard let inputImage = CIImage(image: image) else {
            print("Failed to create CIImage")
            return image
        }

        // Background removal logic
        guard let maskImage = createMask(from: inputImage) else { // Uses createMask helper function
            print("Failed to create mask")
            return image
        }

        let outputImage = applyMask(mask: maskImage, to: inputImage) // Uses applyMask helper function

        // Convert the processed CIImage to UIImage while preserving the original orientation
        return convertToUIImage(ciImage: outputImage, originalOrientation: image.imageOrientation) // Uses convertToUIImage helper function
    }

    /// Creates a mask for the input image using Vision framework.
    /// - Parameter inputImage: The CIImage to create mask from.
    /// - Returns: A CIImage mask or nil if failed.
    /// - Note: This is a helper function used by removeBackground.
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

    /// Applies the mask to the input image to remove the background.
    /// - Parameters:
    ///   - mask: The mask CIImage.
    ///   - image: The original CIImage.
    /// - Returns: The masked CIImage.
    /// - Note: This is a helper function used by removeBackground.
    private func applyMask(mask: CIImage, to image: CIImage) -> CIImage {
        let filter = CIFilter.blendWithMask()
        filter.inputImage = image
        filter.maskImage = mask
        filter.backgroundImage = CIImage.empty()
        return filter.outputImage!
    }

    /// Converts a CIImage back to UIImage while preserving orientation.
    /// - Parameters:
    ///   - ciImage: The CIImage to convert.
    ///   - originalOrientation: The original UIImage orientation.
    /// - Returns: The converted UIImage.
    /// - Note: This is a helper function used by removeBackground.
    private func convertToUIImage(ciImage: CIImage, originalOrientation: UIImage.Orientation = .up) -> UIImage {
        guard let cgImage = CIContext(options: nil).createCGImage(ciImage, from: ciImage.extent) else {
            fatalError("Failed to render CGImage")
        }
        return UIImage(cgImage: cgImage, scale: 1.0, orientation: originalOrientation)
    }

    // MARK: - User Action Functions
    
    /// Presents options to add a photo (camera or photo library)
    /// - Note: This function is triggered when the user taps the add photo button.
    func addPhoto () {
        showingOption = true
    }
    
    /// Confirms and saves the clothing item to the data model.
    /// - Note: This function handles both creating a new clothing item and updating an existing one.
    /// It uses helper functions to manage category relationships and background removal.
    func Confirm() {
        let color = CustomColor(color: chosenColor)

        if let clothingItem = existingClothingItem {
            // Update existing item
            clothingItem.name = clothingItemName
            clothingItem.notes = clothingItemNotes
            clothingItem.color = color
            clothingItem.status = clothingItemStatus
            clothingItem.dirty = (clothingItemStatus == 1)
            clothingItem.washing = (clothingItemStatus == 2)
            clothingItem.ironable = clothingItemIronable
            clothingItem.size = clothingItemSize
            clothingItem.season = Array(clothingItemSeason)
            clothingItem.lastWorn = clothingItemLastWorn

            // Save image
            if let originalImage = displayedImage, let imageData = originalImage.pngData() {
                clothingItem.picture = imageData
            }

            // Update category relationships
            updateCategoryRelationships(for: clothingItem, newCategories: Array(clothingItemCategories)) // Uses helper function
        } else {
            // Create new item
            let newClothingItem = ClothingItem(
                name: clothingItemName,
                notes: clothingItemNotes,
                color: color,
                status: clothingItemStatus,
                ironable: clothingItemIronable,
                season: Array(clothingItemSeason),
                size: clothingItemSize,
                lastWorn: clothingItemLastWorn,
                dirty: clothingItemStatus == 1,
                washing: clothingItemStatus == 2
            )

            // Save image
            if let originalImage = displayedImage, let imageData = originalImage.pngData() {
                newClothingItem.picture = imageData
            }

            // Establish relationships
            newClothingItem.clothingItemCategories = Array(clothingItemCategories)
            for category in clothingItemCategories {
                if !category.categoryClothingItems.contains(newClothingItem) {
                    category.categoryClothingItems.append(newClothingItem)
                }
            }

            // Insert new item into the model context
            modelContext.insert(newClothingItem)
        }

        // Save changes to the data model
        do {
            try modelContext.save()
            print("Changes saved successfully.")
        } catch {
            print("Failed to save changes: \(error)")
        }

        dismiss() // Dismiss the view after saving
    }

    // MARK: - Helper Functions for Data Management
    
    /// Updates the category relationships for a clothing item.
    /// - Parameters:
    ///   - clothingItem: The clothing item to update.
    ///   - newCategories: The new categories to assign to the clothing item.
    /// - Note: This function removes the clothing item from old categories and adds it to new ones.
    /// It is used by the Confirm() function when updating an existing clothing item.
    private func updateCategoryRelationships(for clothingItem: ClothingItem, newCategories: [ClothingCategory]) {
        // Remove the clothing item from old categories
        for category in clothingItem.clothingItemCategories {
            category.categoryClothingItems.removeAll { $0 == clothingItem }
        }

        // Assign the new categories to the clothing item
        clothingItem.clothingItemCategories = newCategories

        // Add the clothing item to the new categories
        for category in newCategories {
            if !category.categoryClothingItems.contains(clothingItem) {
                category.categoryClothingItems.append(clothingItem)
            }
        }
    }
    
    /// Updates the selected seasons for the clothing item.
    /// - Parameters:
    ///   - chosenSeason: The season chosen by the user.
    ///   - choice: A boolean indicating whether to add or remove the season.
    /// - Note: This function can be expanded for additional season-related logic if needed.
    private func updateSeason(chosenSeason: Season, choice: Bool) {
        if choice {
            clothingItemSeason.insert(chosenSeason)
        } else {
            clothingItemSeason.remove(chosenSeason)
        }
    }
}


#Preview {
    PievienotApgerbuView()
}

