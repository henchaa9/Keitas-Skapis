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
    
    @Query private var kategorijas: [Kategorija]
    @Query private var apgerbi: [Apgerbs]
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State var apgerbaNosaukums = ""
    @State var apgerbaPiezimes = ""
    
    @State private var isExpandedKategorijas = false
    @State private var isExpandedSezona = false

    @State var apgerbaKategorijas: Set<Kategorija> = []
    
    @State var izveletaKrasa: Color = .white
    @State var apgerbaKrasa: Krasa?
    
    @State var apgerbaStavoklis = 0
    @State var apgerbsGludinams = true
    @State var apgerbaIzmers = 0
    
    let sezonaIzvele = [Sezona.vasara, Sezona.rudens, Sezona.ziema, Sezona.pavasaris]
    @State var apgerbaSezona: Set<Sezona> = []
    
    
    @State var apgerbsPedejoreizVilkts = Date.now
    
    // foto pievienosanai
    @State private var selectedImage: UIImage?
    @State private var isPickerPresented = false
    @State private var sourceType: UIImagePickerController.SourceType?
    
    @State private var showingOption = false
    
    @State private var removeBackground = false // User preference for background removal
    @State private var backgroundRemovedImage: UIImage? // Stores the image with background removed

    var existingApgerbs: Apgerbs?
    
    var displayedImage: UIImage? {
        if removeBackground, let backgroundRemovedImage = backgroundRemovedImage {
            return backgroundRemovedImage
        }
        return selectedImage
    }
    
    init(existingApgerbs: Apgerbs? = nil) {
           self.existingApgerbs = existingApgerbs
           if let apgerbs = existingApgerbs {
               _apgerbaNosaukums = State(initialValue: apgerbs.nosaukums)
               _apgerbaPiezimes = State(initialValue: apgerbs.piezimes)
               _apgerbaKategorijas = State(initialValue: Set(apgerbs.kategorijas))
               _izveletaKrasa = State(initialValue: apgerbs.krasa.color)  // Use the color from `apgerbaKrasa`
               _apgerbaStavoklis = State(initialValue: apgerbs.stavoklis)
               _apgerbsGludinams = State(initialValue: apgerbs.gludinams)
               _apgerbaIzmers = State(initialValue: apgerbs.izmers)
               _apgerbaSezona = State(initialValue: Set(apgerbs.sezona))
               _apgerbsPedejoreizVilkts = State(initialValue: apgerbs.pedejoreizVilkts)
               
               // If there is an image, set it as well
               if let imageData = apgerbs.attels, let image = UIImage(data: imageData) {
                   _selectedImage = State(initialValue: image)
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
                Text("Pievienot Apģērbu").font(.title).bold()
                Spacer()
                Button(action: {dismiss()}) {
                    Image(systemName: "arrowshape.left.fill").font(.title).foregroundStyle(.black)
                }.navigationBarBackButtonHidden(true)
            }.padding()
            Spacer()
            ScrollView {
                VStack (alignment: .leading) {
                    
                    VStack (alignment: .leading) {
                        Button(action: pievienotFoto) {
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
                            Button("Cancel", role: .cancel) { }
                        }
                    }.sheet(isPresented: $isPickerPresented) {
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
                    
                    TextField("Nosaukums", text: $apgerbaNosaukums).textFieldStyle(.roundedBorder).padding(.top, 20)
                    TextField("Piezīmes", text: $apgerbaPiezimes).textFieldStyle(.roundedBorder).padding(.top, 10)
                    
                    
                    VStack(alignment: .leading) {
                        Button(action: { isExpandedKategorijas.toggle() }) {
                            HStack {
                                Text("Kategorijas").foregroundStyle(.black)
                                Spacer()
                                Image(systemName: isExpandedKategorijas ? "chevron.up" : "chevron.down").foregroundStyle(.black)
                            }
                            .padding(10)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                        }
                        
                        if isExpandedKategorijas {
                            VStack {
                                ForEach(kategorijas, id: \.self) { kategorija in
                                    HStack {
                                        Text(kategorija.nosaukums)
                                        Spacer()
                                        if apgerbaKategorijas.contains(kategorija) {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                    .padding()
                                    .onTapGesture {
                                        if apgerbaKategorijas.contains(kategorija) {
                                            apgerbaKategorijas.remove(kategorija)
                                        } else {
                                            apgerbaKategorijas.insert(kategorija)
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
                        get: { izveletaKrasa },
                        set: { jaunaKrasa in
                            izveletaKrasa = jaunaKrasa
                            apgerbaKrasa = Krasa(color: jaunaKrasa)
                        }
                    )).padding(8)
                    
                    Picker("Izmērs", selection: $apgerbaIzmers) {
                        Text("XS").tag(0)
                        Text("S").tag(1)
                        Text("M").tag(3)
                        Text("L").tag(4)
                        Text("XL").tag(5)
                    }.pickerStyle(.segmented).padding(.top, 10)
                    
                    Picker("Stāvoklis", selection: $apgerbaStavoklis) {
                        Text("Tīrs").tag(0)
                        Text("Netīrs").tag(1)
                        Text("Mazgājas").tag(2)
                    }.pickerStyle(.segmented).padding(.top, 10)
                    
                    
                    VStack(alignment: .leading) {
                        Button(action: { isExpandedSezona.toggle() }) {
                            HStack {
                                Text("Sezona").foregroundStyle(.black)
                                Spacer()
                                Image(systemName: isExpandedSezona ? "chevron.up" : "chevron.down").foregroundStyle(.black)
                            }
                            .padding(10)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                        }
                        
                        if isExpandedSezona {
                            VStack {
                                ForEach(sezonaIzvele, id: \.self) { sezona in
                                    HStack {
                                        Text(sezona.rawValue)
                                        Spacer()
                                        if apgerbaSezona.contains(sezona) {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                    .padding()
                                    .onTapGesture {
                                        if apgerbaSezona.contains(sezona) {
                                            apgerbaSezona.remove(sezona)
                                        } else {
                                            apgerbaSezona.insert(sezona)
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
                    
                    
                    DatePicker("Pēdējoreiz vilkts", selection: $apgerbsPedejoreizVilkts, displayedComponents: [.date]).padding(.top, 15).padding(.horizontal, 5)
                    
                    Toggle(isOn: $apgerbsGludinams) {
                        Text("Gludināms")
                    }.padding(.top, 15).padding(.horizontal, 5)
                    
                    HStack {
                        Button (action: apstiprinat) {
                            Text("Apstiprināt").bold()
                        }
                        Spacer()
                    }.padding(.top, 20).padding(.leading, 5)
                    
                }
            }.padding()
        }.preferredColorScheme(.light)
            .background(Image("wardrobe_background")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .blur(radius: 5)
            .edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/))
                                    
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

    
    func pievienotFoto () {
        showingOption = true
    }
    
    func apstiprinat() {
        let krasa = Krasa(color: izveletaKrasa)
        
        if let apgerbs = existingApgerbs {
            // Update existing item
            apgerbs.nosaukums = apgerbaNosaukums
            apgerbs.piezimes = apgerbaPiezimes
            apgerbs.krasa = krasa
            apgerbs.stavoklis = apgerbaStavoklis
            apgerbs.gludinams = apgerbsGludinams
            apgerbs.izmers = apgerbaIzmers
            apgerbs.sezona = Array(apgerbaSezona)
            apgerbs.pedejoreizVilkts = apgerbsPedejoreizVilkts
            if let finalImage = displayedImage {
                if let imageData = finalImage.pngData() {
                    apgerbs.attels = imageData
                }
            }

            
            // Update Kategorijas relationships
            updateKategorijaRelationships(for: apgerbs, newKategorijas: Array(apgerbaKategorijas))
        } else {
            // Create a new item
            let jaunsApgerbs = Apgerbs(
                nosaukums: apgerbaNosaukums,
                piezimes: apgerbaPiezimes,
                krasa: krasa,
                stavoklis: apgerbaStavoklis,
                gludinams: apgerbsGludinams,
                sezona: Array(apgerbaSezona),
                izmers: apgerbaIzmers,
                pedejoreizVilkts: apgerbsPedejoreizVilkts,
                netirs: apgerbaStavoklis == 1,
                mazgajas: apgerbaStavoklis == 2
            )
            if let imageData = selectedImage?.pngData() {
                jaunsApgerbs.attels = imageData
            }
            
            // Establish relationships
            jaunsApgerbs.kategorijas = Array(apgerbaKategorijas)
            for kategorija in apgerbaKategorijas {
                if !kategorija.apgerbi.contains(jaunsApgerbs) {
                    kategorija.apgerbi.append(jaunsApgerbs)
                }
            }
            
            // Insert new item into the model context
            modelContext.insert(jaunsApgerbs)
        }
        
        dismiss()
    }

    private func updateKategorijaRelationships(for apgerbs: Apgerbs, newKategorijas: [Kategorija]) {
        // Remove Apgerbs from old Kategorijas
        for kategorija in apgerbs.kategorijas {
            kategorija.apgerbi.removeAll { $0 == apgerbs }
        }
        
        // Assign new Kategorijas and update their Apgerbi
        apgerbs.kategorijas = newKategorijas
        for kategorija in newKategorijas {
            if !kategorija.apgerbi.contains(apgerbs) {
                kategorija.apgerbi.append(apgerbs)
            }
        }
    }

    
    private func atjaunotSezonu(izveletaSezona: Sezona, izvele: Bool) {
        if izvele {
            apgerbaSezona.insert(izveletaSezona)
        } else {
            apgerbaSezona.remove(izveletaSezona)
        }
    }
}

#Preview {
    PievienotApgerbuView()
}

