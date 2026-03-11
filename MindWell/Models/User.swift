import Foundation

struct User: Codable, Identifiable {
    let id: String
    let name: String
    let email: String
    let birthDate: String?
    let avatarURL: String?
    
    var initials: String {
        let parts = name.split(separator: " ")
        let initials = parts.prefix(2).compactMap { $0.first?.uppercased() }.joined()
        return initials.isEmpty ? "U" : initials
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case birthDate
        case avatarURL
    }
}
