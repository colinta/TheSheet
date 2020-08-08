////
///  Skill.swift
//

struct Skill: Codable {
    let title: String
    let basedOn: String
    let isProficient: Bool

    func resolve(_ sheet: Sheet) -> ResolvedSkill {
        var modifierString = ""
        for column in sheet.columns {
            for control in column.controls {
                guard case let .attributes(attributes) = control else { continue }
                for attribute in attributes {
                    guard attribute.abbreviation == basedOn else { continue }
                    modifierString = attribute.modifier.toModString
                    break
                }
            }
        }
        return ResolvedSkill(skill: self, modifier: modifierString)
    }
}

struct ResolvedSkill {
    let skill: Skill
    let modifier: String

    var title: String { skill.title }
    var basedOn: String { skill.basedOn }
    var isProficient: Bool { skill.isProficient }
}
