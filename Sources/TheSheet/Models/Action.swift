////
///  Action.swift
//

import Ashen

struct Action {
    struct Sub: Codable {
        let title: String?
        let check: Formula?
        let damage: [Roll]
        let type: String?
    }

    let title: String
    let level: String?
    let subactions: [Sub]
    let description: Attributed?
    let isExpanded: Bool

    init(
        title: String, level: String? = nil, check: Formula? = nil, damage: [Roll] = [],
        type: String? = nil,
        description: Attributed? = nil, isExpanded: Bool = false
    ) {
        self.init(
            title: title,
            level: level,
            subactions: [
                Sub(
                    title: nil,
                    check: check,
                    damage: damage,
                    type: type
                )
            ],
            description: description,
            isExpanded: isExpanded
        )
    }

    init(
        title: String, level: String? = nil, subactions: [Sub],
        description: Attributed? = nil, isExpanded: Bool = false
    ) {
        self.title = title
        self.level = level
        self.subactions = subactions
        self.description = description
        self.isExpanded = isExpanded
    }

    func replace(isExpanded: Bool) -> Action {
        Action(
            title: title, level: level, subactions: subactions, description: description,
            isExpanded: isExpanded)
    }
}

extension Action: Codable {
    enum CodingKeys: String, CodingKey {
        case title
        case level
        case subactions
        case description
        case isExpanded
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        title = try values.decode(String.self, forKey: .title)
        level = try values.decode(String?.self, forKey: .level)
        subactions = try values.decode([Sub].self, forKey: .subactions)
        let description = try values.decode(AttributedCoder?.self, forKey: .description)
        self.description = description?.toAttributed()
        isExpanded = try values.decode(Bool.self, forKey: .isExpanded)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(level, forKey: .level)
        try container.encode(subactions, forKey: .subactions)
        try container.encode(description.map(AttributedCoder.init), forKey: .description)
        try container.encode(isExpanded, forKey: .isExpanded)
    }

}
