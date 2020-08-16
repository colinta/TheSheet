////
///  SkillsView.swift
//

import Foundation
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
            Text(skill.modifierString),
            Text(" "),
            Text(skill.basedOn),
            Text(" "),
            Text(skill.title),
        ])
}

func EditSkillsView(_ skills: [Skill], editor: Skill.Editor) -> View<SheetControl.EditMessage> {
    let enumeratedSkills = skills.enumerated()
    let profiencyColumn = Stack(.down, enumeratedSkills.map { index, skill in
        OnLeftClick(
            Text(skill.isProficient ? "[◼]" : "[◦]"),
            SheetControl.EditMessage.atIndex(index, .changeBool(.isProficient, !skill.isProficient))
        )
    })
    let titlesColumn = Stack(.down, enumeratedSkills.map { index, skill in
        OnLeftClick(
            Input(skill.title, onChange: { txt in SheetControl.EditMessage.atIndex(index, .changeString(.title, txt)) }, .isResponder(index == editor.responder)),
            SheetControl.EditMessage.firstResponder(IndexPath(index: index)),
            .highlight(false)
        )
    }).padding(right: 1)
    return Flow(.ltr, [
        (.fixed, profiencyColumn),
        (.fixed, Space().width(1)),
        (.flex1, titlesColumn)
    ])
}
