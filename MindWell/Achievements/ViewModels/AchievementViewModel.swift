import Foundation
import SwiftUI

@MainActor
final class AchievementViewModel: ObservableObject {
    @Published var allAchievements: [AchievementDisplay] = []
    @Published var isLoading = false
    
    weak var userProgressVM: UserProgressViewModel?
    
    init() {}
    
    func loadAchievements() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let models = try await NetworkManager.shared.get([AchievementModel].self, from: "/achievements")
            
            if let userProgress = userProgressVM?.userProgress {
                updateAchievementStatus(models: models, userProgress: userProgress)
            } else {
                self.allAchievements = models
                    .map { AchievementDisplay(achievement: $0, isUnlocked: false, userProgress: 0) }
                    .sorted { ($0.achievement.requiredLevel ?? 0) < ($1.achievement.requiredLevel ?? 0) }
            }
            
        } catch {
            print("Error loading achievements: \(error)")
        }
    }
    
    private func updateAchievementStatus(models: [AchievementModel], userProgress: UserProgressResponse) {
        let unlockedIds = Set(userProgress.achievements.map { $0.id })
        self.allAchievements = models
            .map { model in
                AchievementDisplay(
                    achievement: model,
                    isUnlocked: unlockedIds.contains(model.id),
                    userProgress: getCurrentProgress(for: model, userProgress: userProgress)
                )
            }
            .sorted { ($0.achievement.requiredLevel ?? 0) < ($1.achievement.requiredLevel ?? 0) }
    }
    
    private func getCurrentProgress(for model: AchievementModel, userProgress: UserProgressResponse) -> Int {
        switch model.conditionType {
        case "moodStreak": return userProgress.emotionStreak
        case "totalMinutes": return userProgress.totalMinutesWatched
        case "totalTasks": return userProgress.tasksCompleted
        case "purchase": return userProgress.purchaseCount ?? 0
        case "level": return userProgress.level
        default: return 0
        }
    }
    
    func checkAndUnlockAchievements() async {
        guard let userProgress = userProgressVM?.userProgress else {
            print("userProgress doesn't exist")
            return
        }
        
        if allAchievements.isEmpty {
            await loadAchievements()
        } else {
            updateAchievementStatus(models: allAchievements.map { $0.achievement }, userProgress: userProgress)
        }
        
        for (idx, ach) in allAchievements.enumerated() {
            if ach.isUnlocked { continue }
            let currentProgress = getCurrentProgress(for: ach.achievement, userProgress: userProgress)
            let target = ach.achievement.conditionValue
            if currentProgress >= target {
                allAchievements[idx] = AchievementDisplay(achievement: ach.achievement, isUnlocked: true, userProgress: currentProgress)
                await unlockAchievement(id: ach.id)
            }
        }
    }
    
    private func unlockAchievement(id: String) async {
        do {
            let _: UnlockAchievementResponse = try await NetworkManager.shared.post(UnlockAchievementResponse.self, to: "/achievements/\(id)/unlock", body: EmptyBody())
            await userProgressVM?.loadProgress()
            await loadAchievements()
        } catch {
            print("Error unlocking achievement \(id): \(error)")
        }
    }
}
