//
//  ApgerbsDetailView.swift
//  Keitas Skapis
//
//  Created by Henrijs Obolevics on 27/12/2024.
//

import SwiftUI
import SwiftData

struct ApgerbsDetailView: View {
    let apgerbs: Apgerbs
    var onEdit: () -> Void
    var onDelete: () -> Void

    @EnvironmentObject private var chosenManager: ChosenManager
    @State private var selectedStavoklis: String
    @Environment(\.dismiss) var dismiss
    @State private var image: UIImage? // State to hold the loaded image

    init(apgerbs: Apgerbs, onEdit: @escaping () -> Void, onDelete: @escaping () -> Void) {
        self.apgerbs = apgerbs
        self.onEdit = onEdit
        self.onDelete = onDelete
        _selectedStavoklis = State(initialValue: apgerbs.netirs ? "Netīrs" : (apgerbs.mazgajas ? "Mazgājas" : "Tīrs"))
    }

    private var isChosen: Bool {
        chosenManager.chosenApgerbi.contains { $0.id == apgerbs.id }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Button("Aizvērt") {
                    dismiss()
                }
                
                HStack {
                    Text(apgerbs.nosaukums)
                        .font(.title)
                        .bold()
                        .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                    
                    Spacer()
                    
                    Button(action: toggleFavorite) {
                        Image(systemName: apgerbs.isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(.red).font(.title)
                            .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                    }
                }
                
                // Last Worn
                Text("Pēdējoreiz vilkts: \(formattedDate(apgerbs.pedejoreizVilkts))")
                    .font(.subheadline)

                // Image or Fallback
                HStack {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                    } else {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height: 150)
                            .foregroundColor(.gray)
                            .opacity(0.5)
                            .padding(.vertical, 10)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)


                Button {
                    if isChosen {
                        chosenManager.remove(apgerbs)
                    } else {
                        chosenManager.add(apgerbs)
                    }
                } label: {
                    Text(isChosen ? "Izvēlēts" : "Izvēlēties")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isChosen ? Color.yellow : Color.green)
                        .foregroundColor(isChosen ? .black : .white)
                        .cornerRadius(8)
                }.shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                
                // Stavoklis
                HStack {
                    Text("Stāvoklis: ").bold()
                    Text("\(selectedStavoklis)")
                        .bold()
                        .foregroundColor(colorForStavoklis(selectedStavoklis))
                }
                
                Picker("Stāvoklis", selection: $selectedStavoklis) {
                    Text("Tīrs").tag("Tīrs")
                    Text("Netīrs").tag("Netīrs")
                    Text("Mazgājas").tag("Mazgājas")
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: selectedStavoklis) { _, newValue in
                    updateStavoklis(newValue)
                }

                // Categories
                Text("Kategorijas")
                    .font(.headline)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 70), spacing: 5)], spacing: 5) {
                    ForEach(apgerbs.kategorijas, id: \.id) { kategorija in
                        Text(kategorija.nosaukums)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .padding(8)
                            .frame(minWidth: 70)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
                
                // Seasons
                Text("Sezonas")
                    .font(.headline)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 70), spacing: 5)], spacing: 5) {
                    ForEach(apgerbs.sezona, id: \.self) { sezona in
                        Text(sezona.rawValue)
                            .padding(8)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
                
                // Color, Size, Gludinams
                HStack {
                    HStack {
                        Text("Krāsa: ").bold()
                        Circle()
                            .fill(apgerbs.krasa.color)
                            .frame(width: 24, height: 24)
                            .overlay(Circle().stroke(Color(.black), lineWidth: 1))
                    }
                    Spacer()
                    Text("Izmērs: \(sizeLetter(for: apgerbs.izmers))")
                        .bold()
                    Spacer()
                    Text(apgerbs.gludinams ? "Gludināms" : "Negludināms")
                        .foregroundColor(apgerbs.gludinams ? .green : .red).bold()
                }

                // Piezīmes
                Text("Piezīmes").bold()
                Text(apgerbs.piezimes)

                // Edit and Delete Buttons
                Button(action: onEdit) {
                    Text("Rediģēt")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.blue)
                        .background(Color(.white))
                        .cornerRadius(8)
                }.padding(.bottom, -10).padding(.top, 5)

                Button(action: onDelete) {
                    Text("Dzēst")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.red)
                        .background(Color(.white))
                        .cornerRadius(8)
                }
            }
            .padding()
        }
        .background(Color(.systemGray6))
        .onAppear {
            loadImage()
        }
    }

    private func toggleFavorite() {
        apgerbs.isFavorite.toggle()
        try? apgerbs.modelContext?.save()
    }
    
    private func loadImage() {
        apgerbs.loadImage { loadedImage in
            self.image = loadedImage
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func sizeLetter(for size: Int) -> String {
        switch size {
        case 0: return "XS"
        case 1: return "S"
        case 2: return "M"
        case 3: return "L"
        case 4: return "XL"
        default: return "Nezināms"
        }
    }

    private func colorForStavoklis(_ stavoklis: String) -> Color {
        switch stavoklis {
        case "Tīrs":
            return .green
        case "Netīrs":
            return .red
        case "Mazgājas":
            return .yellow
        default:
            return .gray
        }
    }

    private func updateStavoklis(_ newValue: String) {
        switch newValue {
        case "Tīrs":
            apgerbs.netirs = false
            apgerbs.mazgajas = false
        case "Netīrs":
            apgerbs.netirs = true
            apgerbs.mazgajas = false
        case "Mazgājas":
            apgerbs.netirs = false
            apgerbs.mazgajas = true
        default:
            break
        }
        try? apgerbs.modelContext?.save()
    }
}

