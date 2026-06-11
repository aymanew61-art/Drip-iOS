import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem { Label("Home", systemImage: "house.fill") }
                    .tag(0)
                WardrobeView()
                    .tabItem { Label("Schrank", systemImage: "tshirt.fill") }
                    .tag(1)
                DressMeView()
                    .tabItem { Label("Dress Me", systemImage: "sparkles") }
                    .tag(2)
                OutfitsView()
                    .tabItem { Label("Outfits", systemImage: "person.crop.square.fill") }
                    .tag(3)
                StatsView()
                    .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
                    .tag(4)
            }
            .tint(AppTheme.accent)
        }
    }
}
