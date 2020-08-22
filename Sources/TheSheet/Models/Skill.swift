////
///  Skill.swift
//

struct Skill: Codable {
    let title: String
    let basedOn: String
    let isProficient: Bool

    func resolve(_ sheet: Sheet) -> ResolvedSkill {
        ResolvedSkill(
            skill: self,
            modifierString: basedOn.isEmpty
            ? ""
            : Operation.variable(basedOn + ".Mod").eval(sheet)
                .toReadable)
    }

    func replace(title: String) -> Skill {
        Skill(title: title, basedOn: basedOn, isProficient: isProficient)
    }

    func replace(basedOn: String) -> Skill {
        Skill(title: title, basedOn: basedOn, isProficient: isProficient)
    }

    func replace(isProficient: Bool) -> Skill {
        Skill(title: title, basedOn: basedOn, isProficient: isProficient)
    }
}

struct ResolvedSkill {
    let skill: Skill
    let modifierString: String

    var title: String { skill.title }
    var basedOn: String { skill.basedOn }
    var isProficient: Bool { skill.isProficient }
}
