import Foundation

// MARK: - Circle Chat
struct CircleChat: Codable, Identifiable {
    let id: String
    let sender: User
    let content: String
    let createdAt: String
    let circle: String
    let replyTo: ChatReply?
    let mediaUrls: [String]
    let readBy: [ReadByUser]
    let isEdited: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, sender, content, circle
        case createdAt = "created_at"
        case replyTo = "reply_to"
        case mediaUrls = "media_urls"
        case readBy = "read_by"
        case isEdited = "is_edited"
    }
}

struct ReadByUser: Codable {
    let id: String
    let username: String
}

struct ChatReply: Codable {
    let id: String
    let content: String
    let sender: User
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, content, sender
        case createdAt = "created_at"
    }
} 