import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authVM: UserAuthViewModel
    @EnvironmentObject var meditationVM: MeditationLibraryViewModel
    
    var body: some View {
        Group {
            if authVM.isCheckingAuth {
                ProgressView()
                    .scaleEffect(1.5)
            } else if authVM.isLoggedIn {
                NavigationStack(path: $meditationVM.navigationPath) {
                    MainTabView()
                        .navigationDestination(for: MeditationLibraryViewModel.NavigationDestination.self) { destination in
                            switch destination {
                            case .favourites:
                                FavouritesView()
                            case .history:
                                HistoryView()
                            case .detail(let id, let backTitle):
                                MeditationDetailView(
                                    meditationId: id,
                                    backTitle: backTitle
                                )
                            }
                        }
                }
            } else {
                LoginView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: authVM.isLoggedIn)
        .onAppear {
            authVM.checkTokenAndLoadUser()
        }
    }
}
