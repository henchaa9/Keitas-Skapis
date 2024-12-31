//
//  ApgerbsDetailView.swift
//  Keitas Skapis
//
//  Created by Henrijs Obolevics on 27/12/2024.
//

import SwiftUI
import SwiftData

struct ApgerbsDetailView: View {
    let clothingItem: ClothingItem
    var onEdit: () -> Void
    var onDelete: () -> Void

    @EnvironmentObject private var chosenManager: ChosenManager
    @State private var selectedStatus: String
    @Environment(\.dismiss) var dismiss
    @State private var image: UIImage? // State to hold the loaded image

    init(clothingItem: ClothingItem, onEdit: @escaping () -> Void, onDelete: @escaping () -> Void) {
        self.clothingItem = clothingItem
        self.onEdit = onEdit
        self.onDelete = onDelete
        _selectedStatus = State(initialValue: clothingItem.dirty ? "Netīrs" : (clothingItem.washing ? "Mazgājas" : "Tīrs"))
    }

    private var isChosen: Bool {
        chosenManager.chosenClothingItems.contains { $0.id == clothingItem.id }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Button("Aizvērt") {
                    dismiss()
                }
                
                HStack {
                    Text(clothingItem.name)
                        .font(.title)
                        .bold()
                        .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                    
                    Spacer()
                    
                    Button(action: toggleFavorite) {
                        Image(systemName: clothingItem.isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(.red).font(.title)
                            .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                    }
                }
                
                // Last Worn
                Text("Pēdējoreiz vilkts: \(formattedDate(clothingItem.lastWorn))")
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
                        chosenManager.remove(clothingItem)
                    } else {
                        chosenManager.add(clothingItem)
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
                    Text("\(selectedStatus)")
                        .bold()
                        .foregroundColor(colorForStatus(selectedStatus))
                }
                
                Picker("Stāvoklis", selection: $selectedStatus) {
                    Text("Tīrs").tag("Tīrs")
                    Text("Netīrs").tag("Netīrs")
                    Text("Mazgājas").tag("Mazgājas")
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: selectedStatus) { _, newValue in
                    updateStatus(newValue)
                }

                // Categories
                Text("Kategorijas")
                    .font(.headline)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 70), spacing: 5)], spacing: 5) {
                    ForEach(clothingItem.clothingItemCategories, id: \.id) { category in
                        Text(category.name)
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
                    ForEach(clothingItem.season, id: \.self) { season in
                        Text(season.rawValue)
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
                            .fill(clothingItem.color.color)
                            .frame(width: 24, height: 24)
                            .overlay(Circle().stroke(Color(.black), lineWidth: 1))
                    }
                    Spacer()
                    Text("Izmērs: \(sizeLetter(for: clothingItem.size))")
                        .bold()
                    Spacer()
                    Text(clothingItem.ironable ? "Gludināms" : "Negludināms")
                        .foregroundColor(clothingItem.ironable ? .green : .red).bold()
                }

                // Piezīmes
                Text("Piezīmes").bold()
                Text(clothingItem.notes)

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
        clothingItem.isFavorite.toggle()
        try? clothingItem.modelContext?.save()
    }
    
    private func loadImage() {
        clothingItem.loadImage { loadedImage in
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

    private func colorForStatus(_ status: String) -> Color {
        switch status {
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

    private func updateStatus(_ newValue: String) {
        switch newValue {
        case "Tīrs":
            clothingItem.dirty = false
            clothingItem.washing = false
        case "Netīrs":
            clothingItem.dirty = true
            clothingItem.washing = false
        case "Mazgājas":
            clothingItem.dirty = false
            clothingItem.washing = true
        default:
            break
        }
        try? clothingItem.modelContext?.save()
    }
}

