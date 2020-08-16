////
///  Skill.swift
//

struct Skill: Codable {
    let title: String
    let basedOn: String
    let isProficient: Bool

    struct Editor {
        let responder: Int?

        func replace(responder: Int) -> Editor {
            Editor(responder: responder)
        }
    }

    func resolve(_ sheet: Sheet) -> ResolvedSkill {
        ResolvedSkill(
            skill: self,
            modifierString:
                Operation.eval(sheet, .modifier(.variable(basedOn + ".Mod")))
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
