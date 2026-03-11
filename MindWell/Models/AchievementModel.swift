import Foundation

struct AchievementModel: Identifiable, Codable {
    let _id: String
    let code: String
    let title: String
    let description: String?
    let conditionType: String
    let conditionValue: Int
    let pointsReward: Int
    let xpReward: Int
    let icon: String?
    let requiredLevel: Int?
    var id: String { _id }
    enum CodingKeys: String, CodingKey {
        case _id, code, title, description, conditionType, conditionValue, pointsReward, xpReward, icon, requiredLevel
    }
}

struct AchievementDisplay: Identifiable, Hashable, Equatable {
    let achievement: AchievementModel
    let isUnlocked: Bool
    var userProgress: Int
    var id: String { achievement.id }
    var progressRatio: Double { Double(userProgress) / Double(achievement.conditionValue) }
    var progressText: String { "\(userProgress)/\(achievement.conditionValue)" }
    static func == (lhs: AchievementDisplay, rhs: AchievementDisplay) -> Bool {
        lhs.id == rhs.id && lhs.isUnlocked == rhs.isUnlocked && lhs.userProgress == rhs.userProgress
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(isUnlocked)
        hasher.combine(userProgress)
    }
}

struct UnlockAchievementResponse: Decodable {
    let unlocked: Bool
    let reason: String?
    let achievement: AchievementModel?
}

struct EmptyBody: Encodable {}
