import Foundation

// 日志历史 DTO：兼容后端返回的 note（单数）或 notes（复数）字段
struct LogHistoryResponse: Codable {
    let logs: [LogItem]
    let pagination: Pagination?
}

struct Pagination: Codable {
    let total: Int?
    let limit: Int?
    let offset: Int?
    let hasMore: Bool?
}

struct LogItem: Codable, Identifiable {
    let id: String
    let type: String
    let tags: [String]?
    let value: Int?
    let unit: String?
    let note: String? // unified view
    let recordedAt: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, type, tags, value, unit, recordedAt, createdAt
        case note
        case notes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(String.self, forKey: .type)
        tags = try container.decodeIfPresent([String].self, forKey: .tags)
        value = try container.decodeIfPresent(Int.self, forKey: .value)
        unit = try container.decodeIfPresent(String.self, forKey: .unit)
        recordedAt = try container.decodeIfPresent(String.self, forKey: .recordedAt)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)

        // 兼容 note（String|null） 和 notes（String|null 或 [String]）
        if let singleNote = try container.decodeIfPresent(String.self, forKey: .note) {
            note = singleNote
        } else if let notesString = try? container.decodeIfPresent(String.self, forKey: .notes) {
            note = notesString
        } else if let notesArray = try? container.decodeIfPresent([String].self, forKey: .notes) {
            // 将数组拼接为单字符串（按逗号）
            note = notesArray.joined(separator: ", ")
        } else {
            note = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(tags, forKey: .tags)
        try container.encodeIfPresent(value, forKey: .value)
        try container.encodeIfPresent(unit, forKey: .unit)
        try container.encodeIfPresent(note, forKey: .note)
        try container.encodeIfPresent(recordedAt, forKey: .recordedAt)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
    }
}
