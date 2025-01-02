
import SwiftUI
import SwiftData
import UIKit
import Vision

struct PievienotApgerbuView: View {
    
    // MARK: - Datu vaicājumi
    
    @Query private var categories: [ClothingCategory]
    @Query private var clothingItems: [ClothingItem]
    
    // MARK: - Vides mainīgie
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Stāvokļu mainīgie
    
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
    @State private var removeBackground = false
    @State private var backgroundRemovedImage: UIImage?
    var existingClothingItem: ClothingItem?
    
    // MARK: - Kļūdu apstrādes mainīgie
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""

    
    // MARK: - Aprēķināmie parametri
    
    // Determines which image to display based on the removeBackground toggle
    var displayedImage: UIImage? {
        if removeBackground {
            return backgroundRemovedImage ?? selectedImage
        }
        return selectedImage
    }

    // MARK: - Initialization
    
    // Inicializē skatu ar esošu apģērbu, ja tāds padots (rediģēšanai)
    /// - Parameter existingClothingItem: Apģērbs, ko rediģēt (neobligāts)
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

            // Ielādē un apstrādā attēlu
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

    // MARK: - Attēla izvēle
    
    // UIViewControllerRepresentable struct, kas nodrošina attēla izvēli no galerijas vai izmantojot kameru
    struct ImagePicker: UIViewControllerRepresentable {
        @Environment(\.presentationMode) private var presentationMode
        @Binding var selectedImage: UIImage?
        var sourceType: UIImagePickerController.SourceType

        // Izveido UIImagePickerController
        func makeUIViewController(context: Context) -> UIImagePickerController {
            let picker = UIImagePickerController()
            picker.delegate = context.coordinator
            picker.sourceType = sourceType
            return picker
        }

        // Atjaunina UIImagePickerController (šeit netiek izmantots)
        func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

        // Izveido koordinatoru
        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }

        // Coordinator klase UIImagePickerControllerDelegate metožu kontrolēšanai
        class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
            let parent: ImagePicker

            init(_ parent: ImagePicker) {
                self.parent = parent
            }

            // Kontrolē attēla izvēli
            func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
                if let image = info[.originalImage] as? UIImage {
                    parent.selectedImage = image
                }
                parent.presentationMode.wrappedValue.dismiss()
            }
            
            // Kontrolē attēla izvēles atcelšanu
            func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
                parent.presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    // MARK: - Skata saturs
    
    var body: some View {
        VStack {
            // Galvene
            HStack {
                Text("Pievienot Apģērbu")
                    .font(.title)
                    .bold()
                    .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                Spacer()
                Button(action: { dismiss() }) {
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
            
            // Iespējota stumšana uz leju
            ScrollView {
                VStack (alignment: .leading) {
                    // Attēla izvēle
                    VStack (alignment: .leading) {
                        Button(action: addPhoto) { // Button to add photo
                            ZStack {
                                if let displayedImage = displayedImage {
                                    // Parāda attēlu dinamiski balstoties uz izvēli
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
                        .confirmationDialog("Pievienot attēlu", isPresented: $showingOption) { // Attēla ievade
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
                    .sheet(isPresented: $isPickerPresented) { // Parāda dialogu attēla izvēlei
                        if let sourceType = sourceType {
                            ImagePicker(selectedImage: $selectedImage, sourceType: sourceType)
                        }
                    }
                    
                    // Slēdzis fona noņemšanai
                    Toggle("Noņemt fonu", isOn: $removeBackground)
                        .padding(.top, 20)
                        .onChange(of: removeBackground) { _, newValue in
                            if newValue, let selectedImage = selectedImage {
                                backgroundRemovedImage = removeBackground(from: selectedImage) // Izmanto palīgmetodi
                            }
                        }

                    // Nosaukuma un Piezīmju ievade
                    TextField("Nosaukums", text: $clothingItemName)
                        .textFieldStyle(.roundedBorder)
                        .padding(.top, 20)
                        .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                    TextField("Piezīmes", text: $clothingItemNotes)
                        .textFieldStyle(.roundedBorder)
                        .padding(.top, 10)
                        .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                    
                    // Kategoriju izvēle
                    VStack(alignment: .leading) {
                        Button(action: { isExpandedCategories.toggle() }) {
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
                                ForEach(categories, id: \.self) { category in // Izplests kategoriju saraksts
                                    HStack {
                                        Text(category.name)
                                        Spacer()
                                        if clothingItemCategories.contains(category) {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                    .padding()
                                    .onTapGesture { // Reģistrē pieskārienu uz kategorijas
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
                    
                    // Krāsas izvēle
                    ColorPicker("Krāsa", selection: Binding(
                        get: { chosenColor },
                        set: { newColor in
                            chosenColor = newColor
                            clothingItemColor = CustomColor(color: newColor) // Updates custom color
                        }
                    ))
                    .padding(8)
                    
                    // Izmēra izvēle
                    Picker("Izmērs", selection: $clothingItemSize) {
                        Text("XS").tag(0)
                        Text("S").tag(1)
                        Text("M").tag(2)
                        Text("L").tag(3)
                        Text("XL").tag(4)
                    }
                    .pickerStyle(.segmented)
                    .padding(.top, 10)
                    
                    // Stāvokļa izvēle
                    Picker("Stāvoklis", selection: $clothingItemStatus) {
                        Text("Tīrs").tag(0)
                        Text("Netīrs").tag(1)
                        Text("Mazgājas").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.top, 10)
                    
                    // Sezonas izvēle
                    VStack(alignment: .leading) {
                        Button(action: { isExpandedSeason.toggle() }) {
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
                                ForEach(seasonChoise, id: \.self) { season in // Izplestais sezonu saraksts
                                    HStack {
                                        Text(season.rawValue)
                                        Spacer()
                                        if clothingItemSeason.contains(season) {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                    .padding()
                                    .onTapGesture { // Reģistrē pieskārienu sezonai
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
                    
                    // Pēdējoreiz vilkts datuma izvēle
                    DatePicker("Pēdējoreiz vilkts", selection: $clothingItemLastWorn, displayedComponents: [.date])
                        .padding(.top, 15)
                        .padding(.horizontal, 5)
                    
                    // Gludināms slēdzis
                    Toggle(isOn: $clothingItemIronable) {
                        Text("Gludināms")
                    }
                    .padding(.top, 15)
                    .padding(.horizontal, 5)
                    
                    // Apstiprināt poga
                    Button {
                        Confirm()
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
        .preferredColorScheme(.light)
        .hideKeyboardOnTap()
        .alert(isPresented: $showErrorAlert) { // Added alert modifier
            Alert(
                title: Text("Kļūda"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // MARK: - Palīgfunkcijas
    
    // Noņem attēla fonu izmantojot Vision un CoreImage
    /// - Parameter image: oriģinālā UIImage no kuras noņemt fonu.
    /// - Returns: jauna UIImage ar noņemtu fonu vai ar fonu, ja noņemšana neizdodas
    /// - Note: tiek izmantota initializer un kad removeBackground tiek mainīts.
    private func removeBackground(from image: UIImage) -> UIImage {
        guard let inputImage = CIImage(image: image) else {
            print("Failed to create CIImage")
            return image
        }

        // Fona noņemšana
        guard let maskImage = createMask(from: inputImage) else { // Uses createMask helper function
            print("Failed to create mask")
            return image
        }

        let outputImage = applyMask(mask: maskImage, to: inputImage) // izmanto applyMask palīgmetodi

        // Pārvērš apstrādāto CIImage uz UIImage saglabājot orientāciju
        return convertToUIImage(ciImage: outputImage, originalOrientation: image.imageOrientation) // izmanto convertToUIImage palīgmetodi
    }

    // Izveido attēla masku izmantojot Vision
    /// - Parameter inputImage: CIImage attēls, ko apstrādāt.
    /// - Returns: CIImage maska vai nil, ja neizdodas izveidot masku.
    /// - Note: šo metodi izmanto removeBackground.
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

    // Pievieno masku oriģinālajam attēlam, lai noņemtu fonu
    /// - Parameters:
    ///   - mask: CIImage maska.
    ///   - image: Oriģinālais CIImage attēls.
    /// - Returns: Jauns CIImage attēls ar noņemtu fonu.
    /// - Note: šo metodi izmanto removeBackground.
    private func applyMask(mask: CIImage, to image: CIImage) -> CIImage {
        let filter = CIFilter.blendWithMask()
        filter.inputImage = image
        filter.maskImage = mask
        filter.backgroundImage = CIImage.empty()
        return filter.outputImage!
    }

    // Pārvērš CIImage atpakaļ uz UIImage ar oriģinālu orientāciju.
    /// - Parameters:
    ///   - ciImage: CIImage attēls ko pārvērst.
    ///   - originalOrientation: Oriģinālā UIImage attēla orientācija.
    /// - Returns: Jauns UIImage attēls izveidots no CIImage.
    /// - Note: šo metodi izmanto removeBackground.
    private func convertToUIImage(ciImage: CIImage, originalOrientation: UIImage.Orientation = .up) -> UIImage {
        guard let cgImage = CIContext(options: nil).createCGImage(ciImage, from: ciImage.extent) else {
            fatalError("Failed to render CGImage")
        }
        return UIImage(cgImage: cgImage, scale: 1.0, orientation: originalOrientation)
    }

    // MARK: - Lietotāja darbību funkcijas
    
    // Piedāvā pievienot foto izmantojot kameru vai no galerijas
    /// - Note: tiek izsaukta, kad lietotājs piespiež pievienot foto pogu
    func addPhoto () {
        showingOption = true
    }
    
    // Saglabā apģērbu
    /// - Note: Šī funkcija gan saglabā jaunus apģērbus, gan rediģētus
    /// Tā izmanto palīgmetodes fona noņemšanai
    func Confirm() {
        // Pārbauda, vai nosaukums nav tukšs
        guard !clothingItemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Nosaukums nevar būt tukšs."
            showErrorAlert = true
            return
        }
        
        // Saglabā apģērbu
        Task {
            let color = CustomColor(color: chosenColor)
            
            if let clothingItem = existingClothingItem {
                // Saglabā eksistējošu apģērbu
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
                
                // Saglabā attēlu, ja izvēlēts
                if let imageData = displayedImage?.pngData() {
                    clothingItem.picture = imageData
                }
                
                // Atjaunina relācijas
                updateCategoryRelationships(for: clothingItem, newCategories: Array(clothingItemCategories))
            } else {
                // Izveido jaunu apģērbu
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
                
                // Saglabā attēlu, ja izvēlēts
                if let imageData = displayedImage?.pngData() {
                    newClothingItem.picture = imageData
                }
                
                // Izveido relācijas
                newClothingItem.clothingItemCategories = Array(clothingItemCategories)
                for category in clothingItemCategories {
                    if !category.categoryClothingItems.contains(newClothingItem) {
                        category.categoryClothingItems.append(newClothingItem)
                    }
                }
                
                // Saglabā jauno apģērbu
                modelContext.insert(newClothingItem)
            }
            
            // Mēģina saglabāt izmaiņas
            do {
                try modelContext.save()
                dismiss()
            } catch {
                // Kļūdas pārvaldība
                errorMessage = "Neizdevās saglabāt apģērbu"
                showErrorAlert = true
            }
        }
    }


    // MARK: - Palīgfunkcijas datu pārvaldībai
    
    // Atjaunina relācijas ar kategorijām
    /// - Parameters:
    ///   - clothingItem: Apģērbs.
    ///   - newCategories: Jaunās kategorijas.
    /// - Note: Šī funkcija noņem vecās kategorijas no apģērba un pievieno jaunās.
    /// To izmanto Confirm() funkcija atjauninot apģērbu
    private func updateCategoryRelationships(for clothingItem: ClothingItem, newCategories: [ClothingCategory]) {
        // Noņem apģērbu no vecām kategorijām
        for category in clothingItem.clothingItemCategories {
            category.categoryClothingItems.removeAll { $0 == clothingItem }
        }

        // Pievieno jaunās kategorijas apģērbam
        clothingItem.clothingItemCategories = newCategories

        // Pievieno apģērbu jaunajām kategorijām
        for category in newCategories {
            if !category.categoryClothingItems.contains(clothingItem) {
                category.categoryClothingItems.append(clothingItem)
            }
        }
    }
    
    // Atjaunina sezonas apģērbam
    /// - Parameters:
    ///   - chosenSeason: Sezona, ko izvēlas lietotājs.
    ///   - choice: Patiesumvērtība, vai pievienot, vai noņemt sezonu.
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

