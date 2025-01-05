
import SwiftUI

/// An enum representing each bottom tab
enum AppTab {
    case home, favorites, calendar, dirty
}

struct MainTabView: View {
    // Track which tab is currently selected
    @State private var selectedTab: AppTab = .home
    
    // Manager for chosen items, if needed
    @StateObject private var chosenManager = ChosenManager()
    // Controls the “Izvēlētie” sheet
    @State private var showChosenClothesSheet = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 1) Switch the main content (the "root" screen) based on selectedTab
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

            // 2) Custom tab bar at the bottom with the same styling as your old ToolBar
            HStack {
                // -- Sākums (Home) button
                Button {
                    selectedTab = .home
                } label: {
                    VStack {
                        Image(systemName: "house")
                            .font(.system(size: 24))
                            // Highlight the icon/text if selected
                            .foregroundStyle(selectedTab == .home ? .blue : .black)
                        Text("Sākums")
                            .font(.footnote)
                            .foregroundStyle(selectedTab == .home ? .blue : .black)
                    }
                }
                .frame(maxWidth: .infinity)

                // -- Izvēlētie (sheet), triggered by the cart icon
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
                // The sheet for chosen items
                .sheet(isPresented: $showChosenClothesSheet) {
                    chosenClothingItemsView()
                        .environmentObject(chosenManager)
                }

                // -- Mīļākie (Favorites)
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

                // -- Kalendārs (Calendar)
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

                // -- Tīrīšana (Dirty Items)
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
        // Make chosenManager available to child views
        .environmentObject(chosenManager)
    }
}




