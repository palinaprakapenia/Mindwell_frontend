import Foundation
import SwiftUI
import SocketIO

struct MeditationsResponse: Decodable {
    let meditations: [Meditation]
}

struct FavoriteToggleResponse: Decodable {
    let isFavorite: Bool
}

struct UnlockCheckResponse: Decodable {
    let isUnlocked: Bool
}

@MainActor
final class MeditationLibraryViewModel: ObservableObject {
    
    @Published var allMeditations: [MeditationWithFavorite] = []
    @Published var meditations: [MeditationWithFavorite] = []
    
    @Published var searchText: String = ""
    @Published var selectedCategory: String? = nil
    @Published var selectedDuration: String? = nil
    @Published var selectedDifficulty: String? = nil
    
    @Published var showFavourites = false
    @Published var isInFavouritesContext = false
    @Published var cameFromFavourites = false
    
    @Published var navigationPath = NavigationPath()
    @Published var pendingDailyTaskUserId: String = ""
    
    @Published var activeChallengeMeditationId: String? = nil
    
    private var socket: SocketIOClient!
    
    weak var userprogressVM: UserProgressViewModel?
    weak var achievementVM: AchievementViewModel?
    weak var dailytaskVM: DailyTaskViewModel?
    weak var challengesVM: ChallengesViewModel?
    
    init() {
        setupSocket()
        Task { await fetchMeditations() }
    }
    
    func goToDetail(
        id: String,
        fromFavourites: Bool = false,
        fromHistory: Bool = false,
        fromDailyTask: Bool = false,
        fromChallenge: Bool = false
    ) {
        let title: String
        
        if fromHistory {
            title = "Historia"
        } else if fromFavourites {
            title = "Ulubione"
        } else if fromDailyTask {
            title = "Główna"
        } else if fromChallenge {
            title = "Wyzwanie"
        } else {
            title = "Biblioteka Medytacji"
        }
        
        navigationPath.append(
            NavigationDestination.detail(meditationId: id, backTitle: title)
        )
    }
    
    private func setupSocket() {
        let manager = SocketManager(socketURL: URL(string: API.baseURL)!, config: [.log(false), .compress])
        socket = manager.defaultSocket
        
        socket.on(clientEvent: .connect) { _, _ in
            print("Socket connected")
        }
        
        socket.on("favoriteUpdated") { [weak self] data, _ in
            guard let self = self else { return }
            guard let dataArray = data as? [[String: Any]],
                  let dict = dataArray.first,
                  let id = dict["id"] as? String,
                  let isFavorite = dict["isFavorite"] as? Bool else { return }
            
            if let index = self.allMeditations.firstIndex(where: { $0.id == id }) {
                self.allMeditations[index].isFavorite = isFavorite
                self.applyFilters()
            }
        }
        
        socket.on("progressUpdated") { [weak self] data, _ in
            guard let self = self else { return }
            Task {
                await self.userprogressVM?.loadProgress()
            }
        }
        
        socket.on("achievementUnlocked") { [weak self] data, _ in
            guard let self = self else { return }
            Task {
                await self.achievementVM?.loadAchievements()
            }
        }
        
        socket.connect()
    }
    
    func fetchMeditations() async {
        do {
            let allResponse: MeditationsResponse = try await NetworkManager.shared.get(MeditationsResponse.self, from: "/meditations")
            let favoritesResponse: MeditationsResponse = try await NetworkManager.shared.get(MeditationsResponse.self, from: "/favorites")
            
            let favoriteIds = Set(favoritesResponse.meditations.map { $0.id })
            
            var meditationsWithStatus: [MeditationWithFavorite] = []
            
            for meditation in allResponse.meditations {
                let isFavorite = favoriteIds.contains(meditation.id)
                
                let isUnlocked: Bool
                if meditation.price == 0 {
                    isUnlocked = true
                } else {
                    isUnlocked = await self.isUnlocked(meditation)
                }
                
                let item = MeditationWithFavorite(
                    meditation: meditation,
                    isFavorite: isFavorite,
                    isUnlocked: isUnlocked
                )
                
                meditationsWithStatus.append(item)
            }
            
            allMeditations = meditationsWithStatus
            applyFilters()
            
        } catch {
            print("Error loading meditations: \(error)")
        }
    }
    
    func toggleFavorite(_ meditation: Meditation) async {
        guard let index = allMeditations.firstIndex(where: { $0.id == meditation.id }) else { return }
        
        let newFavorite = !allMeditations[index].isFavorite
        allMeditations[index].isFavorite = newFavorite
        applyFilters()
        
        do {
            let response: FavoriteToggleResponse = try await NetworkManager.shared.post(
                FavoriteToggleResponse.self,
                to: "/favorites/\(meditation.id)/toggle",
                body: EmptyBody()
            )
            
            if response.isFavorite != newFavorite {
                allMeditations[index].isFavorite = !newFavorite
                applyFilters()
            }
        } catch {
            allMeditations[index].isFavorite = !newFavorite
            applyFilters()
            print("Error: \(error)")
        }
    }
    
    func isUnlocked(_ meditation: Meditation) async -> Bool {
        if meditation.price == 0 { return true }
        do {
            let response: UnlockCheckResponse = try await NetworkManager.shared.get(
                UnlockCheckResponse.self,
                from: "/purchases/check/\(meditation.id)"
            )
            return response.isUnlocked
        } catch {
            return false
        }
    }
    
    func applyFilters() {
        meditations = allMeditations.filter { med in
            let matchesSearch = searchText.isEmpty || med.title.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil || med.category == selectedCategory
            let matchesDuration = selectedDuration == nil || med.duration == selectedDuration
            let matchesDifficulty = selectedDifficulty == nil || med.difficulty == selectedDifficulty
            return matchesSearch && matchesCategory && matchesDuration && matchesDifficulty
        }
    }
    
    var favouriteMeditations: [MeditationWithFavorite] {
        allMeditations.filter { $0.isFavorite }
    }
    
    enum NavigationDestination: Hashable {
        case favourites
        case history
        case detail(meditationId: String, backTitle: String)
    }
    
    func goToFavourites() {
        navigationPath.append(NavigationDestination.favourites)
    }
    
    func goToHistory() {
        navigationPath.append(NavigationDestination.history)
    }
    
    func goBack() {
        navigationPath.removeLast()
    }
    
    func goToRoot() {
        navigationPath = NavigationPath()
    }
}


struct MeditationWithFavorite: Identifiable, Hashable {
    let meditation: Meditation
    var isFavorite: Bool
    
    var id: String { meditation.id }
    var title: String { meditation.title }
    var category: String { meditation.category }
    var duration: String { meditation.duration }
    var difficulty: String { meditation.difficulty }
    var videoUrl: String { meditation.videoUrl }
    var credit: String? { meditation.credit }
    var description: String? { meditation.description }
    var price: Double { meditation.price }
    var isPremium: Bool { meditation.isPremium }
    var isUnlocked: Bool = false
    
    static func == (lhs: MeditationWithFavorite, rhs: MeditationWithFavorite) -> Bool {
        lhs.id == rhs.id && lhs.isFavorite == rhs.isFavorite
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(isFavorite)
    }
}
