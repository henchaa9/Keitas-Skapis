
import SwiftUI

// MARK: - Rīkjosla
struct ToolBar: View {
    // MARK: - Vides mainīgie
    @EnvironmentObject private var chosenManager: ChosenManager
    
    // MARK: - Stāvokļu mainīgie
    @State private var showChosenClothesSheet = false

    var body: some View {
        HStack {
            // 1) Sākums
            NavigationLink(destination: ContentView()) {
                VStack {
                    Image(systemName: "house")
                        .font(.system(size: 24))
                        .foregroundStyle(.black)
                    Text("Sākums")
                        .font(.footnote)
                        .foregroundStyle(.black)
                }
            }
            .frame(maxWidth: .infinity)

            // 2) Izvēlētie apģērbi
            Button(action: {
                showChosenClothesSheet = true
            }) {
                VStack {
                    Image(systemName: "cart")
                        .font(.system(size: 24))
                        .foregroundStyle(.black)
                    Text("Izvēlētie")
                        .font(.footnote)
                        .foregroundStyle(.black)
                }
            }
            .frame(maxWidth: .infinity)
            // Parāda lapu piespiežot pogu rīkjoslā
            .sheet(isPresented: $showChosenClothesSheet) {
                IzveletieView()
                    .environmentObject(chosenManager) // padod chosenManager lapai, lai redzētu izvēlētos apģērbus
            }

            // 3) Mīļākie apģērbi
            NavigationLink(destination: FavoritesView()) {
                VStack {
                    Image(systemName: "heart")
                        .font(.system(size: 24))
                        .foregroundStyle(.black)
                    Text("Mīļākie")
                        .font(.footnote)
                        .foregroundStyle(.black)
                }
            }
            .frame(maxWidth: .infinity)

            // 4) Kalendārs
            NavigationLink(destination: CalendarView()) {
                VStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 24))
                        .foregroundStyle(.black)
                    Text("Kalendārs")
                        .font(.footnote)
                        .foregroundStyle(.black)
                }
            }
            .frame(maxWidth: .infinity)

            // 5) Netīrie apģērbi
            NavigationLink(destination: NetirieApgerbiView()) {
                VStack {
                    Image(systemName: "washer")
                        .font(.system(size: 24))
                        .foregroundStyle(.black)
                    Text("Netīrie")
                        .font(.footnote)
                        .foregroundStyle(.black)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.black), lineWidth: 1))
        .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2) 
        .padding(.horizontal, 5)
    }
}




