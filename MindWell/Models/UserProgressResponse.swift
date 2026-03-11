import Foundation

struct ProgressAchievement: Decodable, Identifiable, Equatable {
    let _id: String
    var id: String { _id }
    enum CodingKeys: String, CodingKey { case _id }
}

struct UserProgressResponse: Decodable, Equatable {
    let points: Int
    let xp: Int
    let level: Int
    let emotionStreak: Int
    let totalMinutesWatched: Int
    let tasksCompleted: Int
    let achievements: [ProgressAchievement]
    let purchaseCount: Int?
    
    private enum CodingKeys: String, CodingKey {
        case points, xp, level, emotionStreak, totalMinutesWatched, tasksCompleted, achievements, purchaseCount
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.points = (try? container.decode(Int.self, forKey: .points)) ?? 0
        self.xp = (try? container.decode(Int.self, forKey: .xp)) ?? 0
        self.level = (try? container.decode(Int.self, forKey: .level)) ?? 1
        self.emotionStreak = (try? container.decode(Int.self, forKey: .emotionStreak)) ?? 0
        self.totalMinutesWatched = (try? container.decode(Int.self, forKey: .totalMinutesWatched)) ?? 0
        self.tasksCompleted = (try? container.decode(Int.self, forKey: .tasksCompleted)) ?? 0
        self.achievements = (try? container.decode([ProgressAchievement].self, forKey: .achievements)) ?? []
        self.purchaseCount = try? container.decode(Int.self, forKey: .purchaseCount)
    }
}
