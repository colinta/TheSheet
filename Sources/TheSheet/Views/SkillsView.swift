////
///  SkillsView.swift
//

import Ashen

func SkillsView<Msg>(_ skills: [ResolvedSkill]) -> View<Msg> {
    Box(
        Reactive(skills.map { SkillView($0) }),
        .title("Skills")
    )
}

func SkillView<Msg>(_ skill: ResolvedSkill) -> View<Msg> {
    Stack(
        .ltr,
        [
            skill.isProficient ? Text(" ◼ ") : Text(" ◦ "),
            Text("\(skill.modifier) "),
            Text(skill.basedOn),
            Text(" "),
            Text(skill.title),
        ])
}
