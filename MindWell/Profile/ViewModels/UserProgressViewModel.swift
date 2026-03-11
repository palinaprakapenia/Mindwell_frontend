import Foundation

@MainActor
class UserProgressViewModel: ObservableObject {
    @Published var points = 0
    @Published var xp = 0
    @Published var dailyStreak: Int?
    @Published var userProgress: UserProgressResponse?
    
    weak var achievementVM: AchievementViewModel?
    
    var totalXP: Int { xp }
    var level: Int { userProgress?.level ?? 1 }
    
    var xpInCurrentLevel: Int {
        let thresholds = [0, 100, 300, 500, 700, 1000]
        var prev = 0
        for threshold in thresholds {
            if xp < threshold { return xp - prev }
            prev = threshold
        }
        return (xp - 1000) % 400
    }
    
    var xpToNextLevel: Int {
        let thresholds = [0, 100, 300, 500, 700, 1000]
        for threshold in thresholds {
            if xp < threshold { return threshold - xp }
        }
        return 400 - ((xp - 1000) % 400)
    }
    
    func loadProgress() async {
        do {
            let response: UserProgressResponse = try await NetworkManager.shared.get(UserProgressResponse.self, from: "/userprogress/me")
            self.userProgress = response
            self.points = response.points
            self.xp = response.xp
            self.dailyStreak = response.emotionStreak
            
            if let achievementVM = achievementVM {
                await achievementVM.checkAndUnlockAchievements()
            }
            
        } catch {
            self.points = 0
            self.xp = 0
            self.userProgress = nil
            print("Failed to load user progress:", error)
        }
    }
    
    func refreshActiveGlobalTasks() async {
        do {
            let userTasks: [UserTaskResponse] = try await NetworkManager.shared.get([UserTaskResponse].self, from: "/tasks")
            let activeIds = userTasks
                .filter { $0.taskType == "global" && $0.completed == false }
                .map { $0.taskId }
            await MainActor.run {
                self.activeGlobalTaskIds = activeIds
            }
        } catch {
            print("Failed to load active globals:", error)
        }
    }
    
    @Published var activeGlobalTaskIds: [String] = []
}
