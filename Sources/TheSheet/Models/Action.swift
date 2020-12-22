////
///  Action.swift
//

struct Action: Codable {
    struct Sub: Codable {
        let title: String?
        let check: Operation?
        let damage: Operation?
        let type: String?

        func replace(title: String?) -> Sub {
            Sub(title: title, check: check, damage: damage, type: type)
        }

        func replace(check: Operation?) -> Sub {
            Sub(title: title, check: check, damage: damage, type: type)
        }

        func replace(damage: Operation?) -> Sub {
            Sub(title: title, check: check, damage: damage, type: type)
        }

        func replace(type: String?) -> Sub {
            Sub(title: title, check: check, damage: damage, type: type)
        }
    }

    let title: String
    let level: String?
    let subactions: [Sub]
    let description: String?
    let isExpanded: Bool
    let remainingUses: Int?
    let maxUses: Operation?
    let shouldResetOn: Rest?

    init(
        title: String, level: String? = nil, check: Operation? = nil, damage: Operation? = nil,
        type: String? = nil,
        description: String? = nil, isExpanded: Bool = false,
        remainingUses: Int? = nil, maxUses: Operation? = nil,
        shouldResetOn: Bool = false
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
        remainingUses: Int? = nil, maxUses: Operation? = nil,
        shouldResetOn: Rest? = nil
    ) {
        self.title = title
        self.level = level
        self.subactions = subactions
        self.description = description
        self.isExpanded = isExpanded
        self.remainingUses = remainingUses
        self.maxUses = maxUses
        self.shouldResetOn = shouldResetOn
    }

    func replace(title: String) -> Action {
        Action(
            title: title, level: level, subactions: subactions, description: description,
            isExpanded: isExpanded, remainingUses: remainingUses, maxUses: maxUses,
            shouldResetOn: shouldResetOn)
    }

    func replace(level: String) -> Action {
        Action(
            title: title, level: level.isEmpty ? nil : level, subactions: subactions,
            description: description,
            isExpanded: isExpanded, remainingUses: remainingUses, maxUses: maxUses,
            shouldResetOn: shouldResetOn)
    }

    func replace(description: String) -> Action {
        Action(
            title: title, level: level, subactions: subactions,
            description: description.isEmpty ? nil : description,
            isExpanded: isExpanded, remainingUses: remainingUses, maxUses: maxUses,
            shouldResetOn: shouldResetOn)
    }

    func replace(isExpanded: Bool) -> Action {
        Action(
            title: title, level: level, subactions: subactions, description: description,
            isExpanded: isExpanded, remainingUses: remainingUses, maxUses: maxUses,
            shouldResetOn: shouldResetOn)
    }

    func replace(remainingUses: Int?) -> Action {
        Action(
            title: title, level: level, subactions: subactions, description: description,
            isExpanded: isExpanded, remainingUses: remainingUses, maxUses: maxUses,
            shouldResetOn: shouldResetOn)
    }

    func replace(maxUses: Operation?) -> Action {
        let remainingUses: Int?
        if self.remainingUses == nil, case let .integer(value) = maxUses {
            remainingUses = value
        } else {
            remainingUses = self.remainingUses
        }
        return Action(
            title: title, level: level, subactions: subactions, description: description,
            isExpanded: isExpanded,
            remainingUses: remainingUses,
            maxUses: maxUses,
            shouldResetOn: shouldResetOn)
    }

    func replace(shouldResetOn: Rest?) -> Action {
        Action(
            title: title, level: level, subactions: subactions, description: description,
            isExpanded: isExpanded, remainingUses: remainingUses, maxUses: maxUses,
            shouldResetOn: shouldResetOn)
    }

    func replace(subactions: [Sub]) -> Action {
        Action(
            title: title, level: level, subactions: subactions, description: description,
            isExpanded: isExpanded, remainingUses: remainingUses, maxUses: maxUses,
            shouldResetOn: shouldResetOn)
    }
}
