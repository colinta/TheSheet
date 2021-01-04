////
///  SkillsView.swift
//

import Ashen

func SkillsView(_ skills: [ResolvedSkill]) -> View<ControlMessage> {
    Box(
        Reactive(skills.map { SkillView($0) }),
        .title("Skills")
    )
}

func SkillView(_ skill: ResolvedSkill) -> View<ControlMessage> {
    guard !skill.title.isEmpty else { return Space().height(1) }
    return Stack(
        .ltr,
        [
            Text(" \(skill.expertise.check) "),
            skill.modifierString.isEmpty
                ? Space()
                : Text(skill.modifierString).minWidth(1).padding(right: 1),
            skill.basedOn.isEmpty
                ? Space()
                : Text(skill.basedOn).padding(right: 1),
            Text(skill.title),
        ])
}
