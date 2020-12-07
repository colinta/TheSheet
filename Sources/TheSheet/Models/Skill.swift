////
///  Skill.swift
//

struct Skill: Codable {
    let title: String
    let basedOn: String
    let expertise: Expertise

    enum Expertise: String, Codable {
        case none
        case proficient
        case expert

        var check: String {
            switch self {
            case .none:
                return "◦"
            case .proficient:
                return "◻"
            case .expert:
                return "◼"
            }
        }

        var checkbox: String {
            switch self {
            case .none:
                return "[\(check)]"
            case .proficient:
                return "[\(check)]"
            case .expert:
                return "[\(check)]"
            }
        }
    }

    func resolve(_ sheet: Sheet) -> ResolvedSkill {
        ResolvedSkill(
            skill: self,
            modifierString: basedOn.isEmpty
                ? ""
                : (expertise == .proficient
                    ? Operation.add([
                        Operation.variable(basedOn + ".Mod"),
                        Operation.variable("proficiencyBonus"),
                    ])
                    : (expertise == .expert
                    ? Operation.add([
                        Operation.variable(basedOn + ".Mod"),
                        Operation.multiply([Operation.integer(2), Operation.variable("proficiencyBonus")]),
                    ])
                    : Operation.variable(basedOn + ".Mod")))
                    .eval(sheet)
                    .toReadable)
    }

    func replace(title: String) -> Skill {
        Skill(title: title, basedOn: basedOn, expertise: expertise)
    }

    func replace(basedOn: String) -> Skill {
        Skill(title: title, basedOn: basedOn, expertise: expertise)
    }

    func replace(expertise: Expertise) -> Skill {
        Skill(title: title, basedOn: basedOn, expertise: expertise)
    }
}

struct ResolvedSkill {
    let skill: Skill
    let modifierString: String

    var title: String { skill.title }
    var basedOn: String { skill.basedOn }
    var expertise: Skill.Expertise { skill.expertise }
}
