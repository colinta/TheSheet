////
///  SkillsView.swift
//

import Ashen

func SkillsView(_ skills: [ResolvedSkill]) -> View<SheetControl.Message> {
    Box(
        Reactive(skills.map { SkillView($0) }),
        .title("Skills")
    )
}

func SkillView(_ skill: ResolvedSkill) -> View<SheetControl.Message> {
    Stack(
        .ltr,
        [
            skill.isProficient ? Text(" ◼ ") : Text(" ◦ "),
            Text(skill.modifierString).minWidth(1),
            Text(" "),
            Text(skill.basedOn),
            Text(" "),
            Text(skill.title),
        ])
}
