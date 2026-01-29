import Foundation

// MARK: - Folder Model
struct Folder: Identifiable, Codable {
    let id: UUID
    var name: String
    var createdAt: Date
    var color: String  // Hex color for folder icon

    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        color: String = "#B48C50"
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.color = color
    }
}
