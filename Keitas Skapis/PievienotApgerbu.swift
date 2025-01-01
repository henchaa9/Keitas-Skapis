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
    
    @Query private var categories: [ClothingCategory]
    @Query private var clothingItems: [ClothingItem]
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @State var clothingItemName = ""
    @State var clothingItemNotes = ""
    @State private var isExpandedCategories = false
    @State private var isExpandedSeason = false
    @State var clothingItemCategories: Set<ClothingCategory> = []
    @State var chosenColor: Color = .white
    @State var clothingItemColor: CustomColor?
    @State var clothingItemStatus = 0
    @State var clothingItemIronable = true
    @State var clothingItemSize = 0
    let seasonChoise = [Season.summer, Season.fall, Season.winter, Season.spring]
    @State var clothingItemSeason: Set<Season> = []
    @State var clothingItemLastWorn = Date.now
    @State private var selectedImage: UIImage?
    @State private var isPickerPresented = false
    @State private var sourceType: UIImagePickerController.SourceType?
    @State private var showingOption = false
    @State private var removeBackground = false // User preference for background removal
    @State private var backgroundRemovedImage: UIImage? // Stores the image with background removed
    var existingClothingItem: ClothingItem?
    
    var displayedImage: UIImage? {
        if removeBackground {
            return backgroundRemovedImage ?? selectedImage
        }
        return selectedImage
    }

    
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
                    _backgroundRemovedImage = State(initialValue: removeBackground(from: image))
                } else {
                    _selectedImage = State(initialValue: image)
                }
            }
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
        VStack {
            HStack {
                Text("Pievienot Apģērbu").font(.title).bold().shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                Spacer()
                Button(action: {dismiss()}) {
                    Image(systemName: "arrowshape.left.fill").font(.title).foregroundStyle(.black).shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                }.navigationBarBackButtonHidden(true)
            }.padding().background(Color(.systemGray6)).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.black), lineWidth: 1)).padding(.horizontal, 10).shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
            Spacer()
            ScrollView {
                VStack (alignment: .leading) {
                    VStack (alignment: .leading) {
                        Button(action: addPhoto) {
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
                        .confirmationDialog("Pievienot attēlu", isPresented: $showingOption) {
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
                    }.sheet(isPresented: $isPickerPresented) {
                            if let sourceType = sourceType {
                                ImagePicker(selectedImage: $selectedImage, sourceType: sourceType)
                            }
                        }
                    
                    Toggle("Noņemt fonu", isOn: $removeBackground)
                        .padding(.top, 20)
                        .onChange(of: removeBackground) { _, newValue in
                            if newValue, let selectedImage = selectedImage {
                                backgroundRemovedImage = removeBackground(from: selectedImage)
                            }
                        }

                    
                    TextField("Nosaukums", text: $clothingItemName).textFieldStyle(.roundedBorder).padding(.top, 20).shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                    TextField("Piezīmes", text: $clothingItemNotes).textFieldStyle(.roundedBorder).padding(.top, 10).shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                    
                    
                    VStack(alignment: .leading) {
                        Button(action: { isExpandedCategories.toggle() }) {
                            HStack {
                                Text("Kategorijas").foregroundStyle(.black)
                                Spacer()
                                Image(systemName: isExpandedCategories ? "chevron.up" : "chevron.down").foregroundStyle(.black)
                            }
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                        }
                        
                        if isExpandedCategories {
                            VStack {
                                ForEach(categories, id: \.self) { category in
                                    HStack {
                                        Text(category.name)
                                        Spacer()
                                        if clothingItemCategories.contains(category) {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                    .padding()
                                    .onTapGesture {
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
                    
                    ColorPicker("Krāsa", selection: Binding(
                        get: { chosenColor },
                        set: { newColor in
                            chosenColor = newColor
                            clothingItemColor = CustomColor(color: newColor)
                        }
                    )).padding(8)
                    
                    Picker("Izmērs", selection: $clothingItemSize) {
                        Text("XS").tag(0)
                        Text("S").tag(1)
                        Text("M").tag(2)
                        Text("L").tag(3)
                        Text("XL").tag(4)
                    }.pickerStyle(.segmented).padding(.top, 10)
                    
                    Picker("Stāvoklis", selection: $clothingItemStatus) {
                        Text("Tīrs").tag(0)
                        Text("Netīrs").tag(1)
                        Text("Mazgājas").tag(2)
                    }.pickerStyle(.segmented).padding(.top, 10)
                    
                    
                    VStack(alignment: .leading) {
                        Button(action: { isExpandedSeason.toggle() }) {
                            HStack {
                                Text("Sezona").foregroundStyle(.black)
                                Spacer()
                                Image(systemName: isExpandedSeason ? "chevron.up" : "chevron.down").foregroundStyle(.black)
                            }
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                        }
                        
                        if isExpandedSeason {
                            VStack {
                                ForEach(seasonChoise, id: \.self) { season in
                                    HStack {
                                        Text(season.rawValue)
                                        Spacer()
                                        if clothingItemSeason.contains(season) {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                    .padding()
                                    .onTapGesture {
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
                    
                    
                    DatePicker("Pēdējoreiz vilkts", selection: $clothingItemLastWorn, displayedComponents: [.date]).padding(.top, 15).padding(.horizontal, 5)
                    
                    Toggle(isOn: $clothingItemIronable) {
                        Text("Gludināms")
                    }.padding(.top, 15).padding(.horizontal, 5)
                    
//                    HStack {
//                        Button (action: apstiprinat) {
//                            Text("Apstiprināt").bold()
//                        }
//                        Spacer()
//                    }.padding(.top, 20).padding(.leading, 5)
                    
                    Button {
                        Confirm()
                    } label: {
                        Text("Apstiprināt")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.white)
                            .foregroundColor(.blue)
                            .cornerRadius(10)
                    }.shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2).padding(.vertical, 15).padding(.horizontal, 5)
                    
                }.padding(20)
            }
        }.preferredColorScheme(.light).hideKeyboardOnTap()
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

    
    func addPhoto () {
        showingOption = true
    }
    
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
            updateCategoryRelationships(for: clothingItem, newCategories: Array(clothingItemCategories))
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

        // Save changes
        do {
            try modelContext.save()
            print("Changes saved successfully.")
        } catch {
            print("Failed to save changes: \(error)")
        }

        dismiss()
    }


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

