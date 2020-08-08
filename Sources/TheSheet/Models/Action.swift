////
///  Action.swift
//

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
    let description: String?
    let isExpanded: Bool
    let uses: Int?
    let remainingUses: Int?
    let shouldResetOnLongRest: Bool

    init(
        title: String, level: String? = nil, check: Formula? = nil, damage: [Roll] = [],
        type: String? = nil,
        description: String? = nil, isExpanded: Bool = false,
        uses: Int? = nil, remainingUses: Int? = nil, shouldResetOnLongRest: Bool = false
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
        description: String? = nil, isExpanded: Bool = false,
        uses: Int? = nil, remainingUses: Int? = nil, shouldResetOnLongRest: Bool = false
    ) {
        self.title = title
        self.level = level
        self.subactions = subactions
        self.description = description
        self.isExpanded = isExpanded
        self.uses = uses
        self.remainingUses = remainingUses
        self.shouldResetOnLongRest = shouldResetOnLongRest
    }

    func replace(isExpanded: Bool) -> Action {
        Action(
            title: title, level: level, subactions: subactions, description: description,
            isExpanded: isExpanded, uses: uses, remainingUses: remainingUses,
            shouldResetOnLongRest: shouldResetOnLongRest)
    }

    func replace(remainingUses: Int) -> Action {
        Action(
            title: title, level: level, subactions: subactions, description: description,
            isExpanded: isExpanded, uses: uses, remainingUses: remainingUses,
            shouldResetOnLongRest: shouldResetOnLongRest)
    }
}

extension Action: Codable {
    enum CodingKeys: String, CodingKey {
        case title
        case level
        case subactions
        case description
        case isExpanded
        case uses
        case remainingUses
        case shouldResetOnLongRest
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        title = try values.decode(String.self, forKey: .title)
        level = try? values.decode(String?.self, forKey: .level)
        subactions = try values.decode([Sub].self, forKey: .subactions)
        description = try values.decode(String?.self, forKey: .description)
        isExpanded = try values.decode(Bool.self, forKey: .isExpanded)
        self.uses = try? values.decode(Int.self, forKey: .uses)
        self.remainingUses = try? values.decode(Int.self, forKey: .remainingUses)
        shouldResetOnLongRest =
            (try? values.decode(Bool.self, forKey: .shouldResetOnLongRest)) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        if level != nil {
            try container.encode(level, forKey: .level)
        }
        if description != nil {
            try container.encode(description, forKey: .description)
        }
        if uses != nil {
            try container.encode(uses, forKey: .uses)
        }
        if remainingUses != nil {
            try container.encode(remainingUses, forKey: .remainingUses)
        }
        try container.encode(shouldResetOnLongRest, forKey: .shouldResetOnLongRest)
        try container.encode(subactions, forKey: .subactions)
        try container.encode(isExpanded, forKey: .isExpanded)
    }
}
