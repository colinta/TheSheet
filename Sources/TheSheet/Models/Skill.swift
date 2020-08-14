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
            modifierString:
                Operation.eval(sheet, .modifier(.variable(basedOn + ".Mod")))
                .toReadable)
    }
}

struct ResolvedSkill {
    let skill: Skill
    let modifierString: String

    var title: String { skill.title }
    var basedOn: String { skill.basedOn }
    var isProficient: Bool { skill.isProficient }
}
