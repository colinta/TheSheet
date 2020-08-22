////
///  SkillsEditor.swift
//

import Ashen
import Foundation

func SkillsEditor(_ skills: [Skill], basedOn: [String], editor: AtPathEditor) -> View<
    EditableControl.Message
> {
    if let xy = editor.atXY, xy.x == 1 {
        return SkillsBasedOnSelector(skills: skills, index: xy.y, basedOn: basedOn)
    }

    let nextResponder: IndexPath
    if let xy = editor.atXY {
        nextResponder = IndexPath(indexes: [0, (xy.y + 1) % skills.count])
    } else {
        nextResponder = IndexPath(indexes: [0, 0])
    }

    let enumeratedSkills = skills.enumerated()
    let profiencyColumn = Stack(
        .down,
        enumeratedSkills.map { index, skill in
            OnLeftClick(
                Text(skill.isProficient ? "[◼]" : "[◦]"),
                EditableControl.Message.atIndex(
                    index, .changeBool(.isProficient, !skill.isProficient))
            ).height(1)
        }
    ).padding(right: 1)

    let titlesColumn: View<EditableControl.Message> = Stack(
        .down,
        enumeratedSkills.map { index, skill in
            let isResponder = editor.atXY.map { $0 == Point(x: 0, y: index) } ?? false
            return OnLeftClick(
                Input(
                    skill.title,
                    onChange: { txt in
                        EditableControl.Message.atIndex(index, .changeString(.title, txt))
                    }, .isResponder(isResponder)),
                EditableControl.Message.firstResponder(IndexPath(indexes: [0, index])),
                .highlight(false)
            ).height(1)
        }
    ).padding(right: 1)

    let basedOnColumn: View<EditableControl.Message> = Stack(
        .down,
        enumeratedSkills.map { index, skill in
            return OnLeftClick(
                Stack(.ltr, [Text("["), Text(skill.basedOn).minWidth(3), Text("]")])
                    .height(1),
                EditableControl.Message.firstResponder(IndexPath(indexes: [1, index])))
        }
    ).padding(right: 1)

    let removeColumn: View<EditableControl.Message> = Stack(
        .down,
        enumeratedSkills.map { index, _ in
            return OnLeftClick(
                Text("[x]".foreground(.red)),
                EditableControl.Message.atIndex(index, .remove)
            )
        })
    return Stack(
        .down,
        [
            OnKeyPress(.tab, EditableControl.Message.firstResponder(nextResponder)),
            Flow(
                .ltr,
                [
                    (.fixed, profiencyColumn),
                    (.flex1, titlesColumn),
                    (.fixed, basedOnColumn),
                    (.fixed, removeColumn),
                ]),
            OnLeftClick(Text("[Add]").centered(), EditableControl.Message.add),
        ])
}

func SkillsBasedOnSelector(skills: [Skill], index skillIndex: Int, basedOn: [String]) -> View<
    EditableControl.Message
> {
    let skill = skills[skillIndex]
    return Stack(
        .down,
        [
            Flow(
                .ltr,
                [
                    (.fixed, Text(skill.isProficient ? "[◼]" : "[◦]").padding(right: 1)),
                    (.flex1, Text(skill.title).padding(right: 1)),
                    (.fixed, Text(skill.basedOn).padding(right: 1)),
                    (
                        .fixed,
                        OnLeftClick(
                            Text("[Cancel]".foreground(.red)),
                            EditableControl.Message.noFirstResponder
                        ).height(1)
                    ),
                ]),
            Stack(
                .down,
                basedOn.map { value in
                    OnLeftClick(
                        Text(value).centered(),
                        EditableControl.Message.atIndex(skillIndex, .changeString(.basedOn, value)))
                }),
            OnLeftClick(
                Text("N/A".foreground(.red)).centered(),
                EditableControl.Message.atIndex(skillIndex, .changeString(.basedOn, ""))),
        ]
    )
    .minHeight(skills.count)
}
