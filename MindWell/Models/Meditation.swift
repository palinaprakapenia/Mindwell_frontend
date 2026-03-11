import Foundation

public struct Meditation: Identifiable, Codable, Hashable {
    public let _id: String
    public let title: String
    public let category: String
    public let duration: String
    public let difficulty: String
    public let videoUrl: String
    public let credit: String?
    public let description: String?
    public let language: String?
    public let price: Double
    public let isPremium: Bool
    
    public var id: String { _id }
    
    public init(
        _id: String,
        title: String,
        category: String,
        duration: String,
        difficulty: String,
        videoUrl: String,
        credit: String? = nil,
        description: String? = nil,
        language: String? = "pl",
        price: Double = 0,
        isPremium: Bool = false
    ) {
        self._id = _id
        self.title = title
        self.category = category
        self.duration = duration
        self.difficulty = difficulty
        self.videoUrl = videoUrl
        self.credit = credit
        self.description = description
        self.language = language
        self.price = price
        self.isPremium = isPremium
    }
}
