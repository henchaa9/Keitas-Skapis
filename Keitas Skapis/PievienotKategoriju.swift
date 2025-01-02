
import SwiftUI
import SwiftData
import UIKit
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - ImagePicker

// A UIViewControllerRepresentable struct, kas aptver UIImagePickerController lietošanai SwiftUI.
// Ļauj izvēlēties pievienot attēlu no galerijas vai izmantot kameru
struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) private var presentationMode
    @Binding var selectedImage: UIImage?
    var sourceType: UIImagePickerController.SourceType

    // Izveido un konfigurē UIImagePickerController.
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }

    // Atjaunina UIImagePickerController netiek izmantots.
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    // Izveido Coordinator instanci UIImagePickerControllerDelegate metožu pārvaldībai.
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // Coordinator klase UIImagePickerController pārvaldībai.
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        // Pārvalda attēla izvēli un loga aizvēršanu
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        // Pārvalda atcelšanu
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - PievienotKategorijuView

// Skats kategoriju pievienošanai un rediģēšanai
struct PievienotKategorijuView: View {
    // MARK: - Vides mainīgie
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext

    // MARK: - Stāvokļu mainīgie
    @State var categoryName = ""
    @State private var selectedImage: UIImage?
    @State private var isPickerPresented = false
    @State private var sourceType: UIImagePickerController.SourceType?
    @State private var showingOption = false
    @State private var removeBackground = false
    var existingCategory: ClothingCategory?
    
    // MARK: - Kļūdu apstrādes mainīgie
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""


    // Inicializē skatu ar neobligātu kategoriju rediģēšanas režīmam
    init(existingCategory: ClothingCategory? = nil) {
        self.existingCategory = existingCategory
        _categoryName = State(initialValue: existingCategory?.name ?? "")
        if let imageData = existingCategory?.picture {
            _selectedImage = State(initialValue: UIImage(data: imageData))
        }
        _removeBackground = State(initialValue: existingCategory?.removeBackground ?? false)
    }

    // Izveido attēlojamo attēlu ar noņemtu/nenoņemtu fonu pēc lietotāja izvēles
    var displayedImage: UIImage? {
        if removeBackground, let selectedImage = selectedImage {
            return removeBackground(from: selectedImage)
        }
        return selectedImage
    }

    var body: some View {
        VStack {
            // Galvene
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

            // Ievades lauki
            VStack(alignment: .leading) {
                // Foto pievienošanas poga
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
                // Dialogs ievades izvēlei
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
                // Attēlo ImagePicker lapu
                .sheet(isPresented: $isPickerPresented) {
                    if let sourceType = sourceType {
                        ImagePicker(selectedImage: $selectedImage, sourceType: sourceType)
                    }
                }

                // Slēdzis fona noņemšanai
                Toggle("Noņemt fonu", isOn: $removeBackground)
                    .padding(.top, 20)

                // Lauks kategorijas nosaukumam
                TextField("Nosaukums", text: $categoryName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.top, 20)
                    .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
            }
            .padding(.top, 50)
            .padding(.horizontal, 20)

            Spacer()

            // Saglabāšanas poga
            Button {
                Save()
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
        .alert(isPresented: $showErrorAlert) {
            Alert(
                title: Text("Kļūda"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    // MARK: - Funkcijas

    // Parāda dialogu foto avota izvēlei kamera/galerija
    func addPhoto() {
        showingOption = true
    }

    // Saglabā jaunu/rediģētu kategoriju
    private func Save() {
        // Pārbauda, vai nosaukums nav tukšs
        guard !categoryName.isEmpty else {
            errorMessage = "Kategorijas nosaukums nevar būt tukšs."
            showErrorAlert = true
            return
        }

        Task {
            let imageData = selectedImage?.pngData()
            if let category = existingCategory {
                // Atjaunina kategoriju
                category.name = categoryName
                category.picture = imageData
                category.removeBackground = removeBackground
            } else {
                // Ievieto jaunu kategoriju
                let newKategorija = ClothingCategory(
                    name: categoryName,
                    picture: imageData,
                    removeBackground: removeBackground
                )
                modelContext.insert(newKategorija)
            }

            // Mēģina saglabāt
            do {
                try modelContext.save()
                dismiss() // Aizver skatu, ja saglabāšana ir veiksmīga
            } catch {
                // Kļūdas pārvaldība
                errorMessage = "Neizdevās saglabāt kategoriju: \(error.localizedDescription)"
                showErrorAlert = true
            }
        }
    }


    // MARK: - Palīgfunkcijas

    // Noņem attēla fonu izmantojot Vision un CoreImage
    /// - Parameter image: oriģinālā UIImage no kuras noņemt fonu.
    /// - Returns: jauna UIImage ar noņemtu fonu vai ar fonu, ja noņemšana neizdodas
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

    // Izveido attēla masku izmantojot Vision
    /// - Parameter inputImage: CIImage attēls, ko apstrādāt.
    /// - Returns: CIImage maska vai nil, ja neizdodas izveidot masku.
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
