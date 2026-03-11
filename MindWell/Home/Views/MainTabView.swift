import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    @EnvironmentObject private var meditationVM: MeditationLibraryViewModel
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MainHomeView(selectedTab: $selectedTab)
                .tabItem { Image(systemName: "house.fill").font(.system(size: 26)) }
                .tag(0)
            
            NavigationStack(path: $meditationVM.navigationPath) {
                LibraryView()
            }
            .tabItem { Image(systemName: "magnifyingglass").font(.system(size: 26)) }
            .tag(1)
            
            StatsView()
                .tabItem { Image(systemName: "waveform.path.ecg").font(.system(size: 26)) }
                .tag(2)
            
            ProfileView(selectedTab: $selectedTab)
                .tabItem { Image(systemName: "face.smiling").font(.system(size: 26)) }
                .tag(3)
        }
        .tint(Color(hex: "#6BA59B"))
        .environment(\.selectedTab, $selectedTab)
        .onAppear {
            configureCustomTabBar()
        }
    }
    
    private func configureCustomTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = nil
        appearance.shadowColor = nil
        appearance.shadowImage = UIImage()
        
        if let gradientImage = UIImage(named: "tabbar_gradient") {
            appearance.backgroundImage = gradientImage.resizableImage(withCapInsets: .zero, resizingMode: .stretch)
        }
        
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
