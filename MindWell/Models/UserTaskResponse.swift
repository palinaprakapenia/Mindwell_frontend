import Foundation

struct UserTaskResponse: Decodable {
    let id: String
    let taskId: String
    let userId: String?
    let currentCount: Int
    let currentMinutes: Int
    let completed: Bool
    let takenAt: Date?
    let completedAt: Date?
    let taskType: String?
    let taskCode: String?
    let categories: [String]?
    let createdAt: Date?
    let updatedAt: Date?
    let isDailyCompleted: Bool?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case taskId
        case userId
        case currentCount
        case currentMinutes
        case completed
        case takenAt
        case completedAt
        case taskType
        case taskCode
        case categories
        case createdAt
        case updatedAt
        case isDailyCompleted
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = (try container.decodeIfPresent(String.self, forKey: .id)
                   ?? Self.decodeObjectId(container: container, key: .id))
        ?? ""
        
        self.taskId = (try container.decodeIfPresent(String.self, forKey: .taskId)
                       ?? Self.decodeObjectId(container: container, key: .taskId))
        ?? ""
        
        self.userId = try container.decodeIfPresent(String.self, forKey: .userId)
        self.currentCount = try container.decodeIfPresent(Int.self, forKey: .currentCount) ?? 0
        self.currentMinutes = try container.decodeIfPresent(Int.self, forKey: .currentMinutes) ?? 0
        self.completed = try container.decodeIfPresent(Bool.self, forKey: .completed) ?? false
        self.taskType = try container.decodeIfPresent(String.self, forKey: .taskType)
        self.taskCode = try container.decodeIfPresent(String.self, forKey: .taskCode)
        self.categories = try container.decodeIfPresent([String].self, forKey: .categories)
        
        self.takenAt = try container.decodeIfPresent(Date.self, forKey: .takenAt)
        self.completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        self.isDailyCompleted = try container.decodeIfPresent(Bool.self, forKey: .isDailyCompleted)
    }
    
    private static func decodeObjectId(container: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) -> String? {
        if let wrapper = try? container.decode([String: String].self, forKey: key),
           let oid = wrapper["$oid"] ?? wrapper["_id"] {
            return oid
        }
        return nil
    }
}
