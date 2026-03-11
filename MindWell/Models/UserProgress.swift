import Foundation

struct UserProgress: Codable {
    let points: Int
    let xp: Int
    let level: Int?
    
    enum CodingKeys: String, CodingKey {
        case points, xp, level
    }
}
