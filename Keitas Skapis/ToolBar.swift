
import SwiftUI

///  Lietotnes skati
enum AppTab {
    case home, favorites, calendar, dirty
}

struct MainTabView: View {
    // Izvēlētais skats
    @State private var selectedTab: AppTab = .home
    
    // Chosen manager izvēlētajiem apģērbiem
    @StateObject private var chosenManager = ChosenManager()
    // Kontrolē Izvēlēto apģērbu skatu
    @State private var showChosenClothesSheet = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 1) Maina skatus
            switch selectedTab {
            case .home:
                NavigationStack {
                    HomeView()
                }
            case .favorites:
                NavigationStack {
                    FavoritesView()
                }
            case .calendar:
                NavigationStack {
                    CalendarView()
                }
            case .dirty:
                NavigationStack {
                    DirtyClothingItemsView()
                }
            }

            // 2) Rīkjosla
            HStack {
                // Galvenais skats
                Button {
                    selectedTab = .home
                } label: {
                    VStack {
                        Image(systemName: "house")
                            .font(.system(size: 24))
                            // Iekrāso izvēlētā skata ikonu
                            .foregroundStyle(selectedTab == .home ? .blue : .black)
                        Text("Sākums")
                            .font(.footnote)
                            .foregroundStyle(selectedTab == .home ? .blue : .black)
                    }
                }
                .frame(maxWidth: .infinity)

                // Izvēlēto apģērbu skats
                Button {
                    showChosenClothesSheet = true
                } label: {
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
                .sheet(isPresented: $showChosenClothesSheet) {
                    chosenClothingItemsView()
                        .environmentObject(chosenManager)
                }

                // Mīļāko apģērbu skats
                Button {
                    selectedTab = .favorites
                } label: {
                    VStack {
                        Image(systemName: "heart")
                            .font(.system(size: 24))
                            .foregroundStyle(selectedTab == .favorites ? .blue : .black)
                        Text("Mīļākie")
                            .font(.footnote)
                            .foregroundStyle(selectedTab == .favorites ? .blue : .black)
                    }
                }
                .frame(maxWidth: .infinity)

                // Kalendāra skats
                Button {
                    selectedTab = .calendar
                } label: {
                    VStack {
                        Image(systemName: "calendar")
                            .font(.system(size: 24))
                            .foregroundStyle(selectedTab == .calendar ? .blue : .black)
                        Text("Kalendārs")
                            .font(.footnote)
                            .foregroundStyle(selectedTab == .calendar ? .blue : .black)
                    }
                }
                .frame(maxWidth: .infinity)

                // Tīrīšanas skats
                Button {
                    selectedTab = .dirty
                } label: {
                    VStack {
                        Image(systemName: "washer")
                            .font(.system(size: 24))
                            .foregroundStyle(selectedTab == .dirty ? .blue : .black)
                        Text("Tīrīšana")
                            .font(.footnote)
                            .foregroundStyle(selectedTab == .dirty ? .blue : .black)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.black), lineWidth: 1))
            .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
            .padding(.horizontal, 5)
        }
        // Padara chosenManager redzamu citiem skatiem
        .environmentObject(chosenManager)
    }
}




