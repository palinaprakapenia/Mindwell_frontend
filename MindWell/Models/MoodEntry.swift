import Foundation

struct MoodEntry: Codable, Identifiable {
    let id: String
    let mood: String
    let date: String
    let email: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case mood
        case date
        case email
    }
}

struct MoodStat: Identifiable {
    let id = UUID()
    let mood: String
    let count: Int
    let color: String
}
