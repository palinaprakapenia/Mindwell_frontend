import Foundation

struct TaskModel: Codable, Identifiable, Equatable {
    let id: String
    let code: String
    let title: String
    let description: String?
    let type: String
    let pointsReward: Int
    let xpReward: Int
    
    let targetMeditationId: String?
    let active: Bool
    
    let targetCount: Int?
    let targetMinutes: Int?
    let requiredLevel: Int?
    let priority: Int?
    let categories: [String]
    
    private enum CodingKeys: String, CodingKey {
        case _id, id, code, title, description, type
        case pointsReward, xpReward, targetMeditationId, active
        case targetCount, targetMinutes, requiredLevel, priority, categories
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let _idString = try? container.decode(String.self, forKey: ._id) {
            id = _idString
        } else if let regularId = try? container.decode(String.self, forKey: .id) {
            id = regularId
        } else if let objectId = try? container.decode(ObjectIdWrapper.self, forKey: ._id) {
            id = objectId.value
        } else {
            throw DecodingError.keyNotFound(CodingKeys._id,
                                            DecodingError.Context(codingPath: decoder.codingPath,
                                                                  debugDescription: "Не найден id или _id"))
        }
        
        code = try container.decode(String.self, forKey: .code)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        type = try container.decode(String.self, forKey: .type)
        pointsReward = try container.decode(Int.self, forKey: .pointsReward)
        xpReward = try container.decode(Int.self, forKey: .xpReward)
        targetMeditationId = try container.decodeIfPresent(String.self, forKey: .targetMeditationId)
        active = try container.decode(Bool.self, forKey: .active)
        
        targetCount = try container.decodeIfPresent(Int.self, forKey: .targetCount)
        targetMinutes = try container.decodeIfPresent(Int.self, forKey: .targetMinutes)
        requiredLevel = try container.decodeIfPresent(Int.self, forKey: .requiredLevel)
        priority = try container.decodeIfPresent(Int.self, forKey: .priority)
        categories = try container.decodeIfPresent([String].self, forKey: .categories) ?? []
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: ._id)
        try container.encode(code, forKey: .code)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(type, forKey: .type)
        try container.encode(pointsReward, forKey: .pointsReward)
        try container.encode(xpReward, forKey: .xpReward)
        try container.encodeIfPresent(targetMeditationId, forKey: .targetMeditationId)
        try container.encode(active, forKey: .active)
        try container.encodeIfPresent(targetCount, forKey: .targetCount)
        try container.encodeIfPresent(targetMinutes, forKey: .targetMinutes)
        try container.encodeIfPresent(requiredLevel, forKey: .requiredLevel)
        try container.encodeIfPresent(priority, forKey: .priority)
        try container.encode(categories, forKey: .categories)
    }
}

private struct ObjectIdWrapper: Codable {
    let value: String
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawString = try container.decode(String.self)
        
        if rawString.contains("ObjectId") {
            let start = rawString.firstIndex(of: "\"")!
            let end = rawString.lastIndex(of: "\"")!
            let hex = rawString[rawString.index(after: start)..<end]
            value = String(hex)
        } else {
            value = rawString
        }
    }
}
