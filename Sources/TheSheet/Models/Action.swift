////
///  Action.swift
//

struct Action: Codable {
    struct Sub: Codable {
        let title: String?
        let check: Operation?
        let damage: Operation?
        let type: String?
    }

    let title: String
    let level: String?
    let subactions: [Sub]
    let description: String?
    let isExpanded: Bool
    let remainingUses: Int?
    let maxUses: Int?
    let shouldResetOnLongRest: Bool

    init(
        title: String, level: String? = nil, check: Operation? = nil, damage: Operation? = nil,
        type: String? = nil,
        description: String? = nil, isExpanded: Bool = false,
        remainingUses: Int? = nil, maxUses: Int? = nil,
        shouldResetOnLongRest: Bool = false
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
        remainingUses: Int? = nil, maxUses: Int? = nil,
        shouldResetOnLongRest: Bool = false
    ) {
        self.title = title
        self.level = level
        self.subactions = subactions
        self.description = description
        self.isExpanded = isExpanded
        self.remainingUses = remainingUses
        self.maxUses = maxUses
        self.shouldResetOnLongRest = shouldResetOnLongRest
    }

    func replace(title: String) -> Action {
        Action(
            title: title, level: level, subactions: subactions, description: description,
            isExpanded: isExpanded, remainingUses: remainingUses, maxUses: maxUses,
            shouldResetOnLongRest: shouldResetOnLongRest)
    }

    func replace(level: String) -> Action {
        Action(
            title: title, level: level.isEmpty ? nil : level, subactions: subactions, description: description,
            isExpanded: isExpanded, remainingUses: remainingUses, maxUses: maxUses,
            shouldResetOnLongRest: shouldResetOnLongRest)
    }

    func replace(description: String) -> Action {
        Action(
            title: title, level: level, subactions: subactions, description: description.isEmpty ? nil : description,
            isExpanded: isExpanded, remainingUses: remainingUses, maxUses: maxUses,
            shouldResetOnLongRest: shouldResetOnLongRest)
    }

    func replace(isExpanded: Bool) -> Action {
        Action(
            title: title, level: level, subactions: subactions, description: description,
            isExpanded: isExpanded, remainingUses: remainingUses, maxUses: maxUses,
            shouldResetOnLongRest: shouldResetOnLongRest)
    }

    func replace(remainingUses: Int?) -> Action {
        Action(
            title: title, level: level, subactions: subactions, description: description,
            isExpanded: isExpanded, remainingUses: remainingUses, maxUses: maxUses,
            shouldResetOnLongRest: shouldResetOnLongRest)
    }

    func replace(maxUses: Int?) -> Action {
        Action(
            title: title, level: level, subactions: subactions, description: description,
            isExpanded: isExpanded,
            remainingUses: remainingUses == nil && maxUses != nil
                ? maxUses
                : remainingUses,
            maxUses: maxUses,
            shouldResetOnLongRest: shouldResetOnLongRest)
    }

    func replace(shouldResetOnLongRest: Bool) -> Action {
        Action(
            title: title, level: level, subactions: subactions, description: description,
            isExpanded: isExpanded, remainingUses: remainingUses, maxUses: maxUses,
            shouldResetOnLongRest: shouldResetOnLongRest)
    }

    func replace(subactions: [Sub]) -> Action {
        Action(
            title: title, level: level, subactions: subactions, description: description,
            isExpanded: isExpanded, remainingUses: remainingUses, maxUses: maxUses,
            shouldResetOnLongRest: shouldResetOnLongRest)
    }
}
