////
///  ActionEditor.swift
//

import Foundation
import Ashen

func ActionEditor(_ action: Action, _ editor: AtPathEditor) -> View<EditableControl.Message> {
    let levels = ["Cantrip", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
    let levelSelector: View<EditableControl.Message> =
        Stack(.ltr, [
            Text("Level: "),
            OnLeftClick(Text("---".styled(action.level == nil ? .bold : .none)), .changeString(.level, "")),
        ] + levels.map { level in
            OnLeftClick(Text("[\(level)]".styled(action.level == level ? .bold : .none)), .changeString(.level, level))
                .padding(left: 1)
        })
    let descriptionEditors: [View<EditableControl.Message>] = [
        OnLeftClick(Text("Description:"), .firstResponder([0, 4]), .highlight(false)),
        OnLeftClick(
            Input(action.description ?? "", onChange: { .changeString(.description, $0) },
                .placeholder("(optional)"),
                .isResponder(editor.atPath == [0, 4]),
                .isMultiline(true),
                .wrap(true)),
            .firstResponder([0, 4]), .highlight(false)
        ).padding(left: 4),
    ]
    return Stack(.down,
        [
            PromptInput("Title: ", action.title, .title, path: editor.atPath, index: 0),
            levelSelector,
            PromptInput("Remaining Uses: ", action.remainingUses?.description, .current, path: editor.atPath, index: 2),
            PromptInput("Maximum Uses:   ", action.maxUses?.toEditable, .max, path: editor.atPath, index: 3),
        ]
        + descriptionEditors
        + [
            Text("Actions:").underlined(),
        ]
        + action.subactions.enumerated().map { index, subaction in
            SubactionEditor(action, subaction, index, editor)
        } + [
            OnLeftClick(Text("[+] Add Action".foreground(.green)), .add),
        ])
}

private func PromptInput(_ prompt: String, _ value: String?,
    _ property: EditableControl.Message.Property, path: IndexPath?, index: Int, placeholder: String = ""
) -> View<EditableControl.Message>
{
    OnLeftClick(
        Stack(.ltr, [
            Text(prompt),
            Input(value ?? "", onChange: { .changeString(property, $0) },
                .placeholder(placeholder), .isResponder(path == [0, index])),
        ]),
        .firstResponder([0, index]),
        .highlight(false)
    )
}

private func SubactionEditor(_ action: Action, _ subaction: Action.Sub, _ index: Int, _ editor: AtPathEditor) -> View<EditableControl.Message> {
    Stack(.ltr, [
        Stack(.down, [
            OnLeftClick(Text("Title:"), .firstResponder([index + 1, 1])),
            OnLeftClick(Text("Check:"), .firstResponder([index + 1, 2])),
            OnLeftClick(Text("Damage:"), .firstResponder([index + 1, 3])),
            OnLeftClick(Text("Type:"), .firstResponder([index + 1, 4])),
            Repeating(Text("─".foreground(.black))).height(1),
        ]).padding(right: 1),
        Stack(.down, [
            OnLeftClick(Input(subaction.title ?? "", onChange: { str in .atPath([index + 1, 1], .changeString(.title, str)) }, .isResponder(editor.atPath == [index + 1, 1])).height(1), .firstResponder([index + 1, 1]), .highlight(false)),
            OnLeftClick(Input(subaction.check?.toEditable ?? "", onChange: { str in .atPath([index + 1, 2], .changeString(.check, str)) }, .isResponder(editor.atPath == [index + 1, 2]), .style(.foreground(subaction.check?.isEditing == true ? .red : .none))).height(1), .firstResponder([index + 1, 2]), .highlight(false)),
            OnLeftClick(Input(subaction.damage?.toEditable ?? "", onChange: { str in .atPath([index + 1, 3], .changeString(.damage, str)) }, .isResponder(editor.atPath == [index + 1, 3]), .style(.foreground(subaction.damage?.isEditing == true ? .red : .none))).height(1), .firstResponder([index + 1, 3]), .highlight(false)),
            OnLeftClick(Input(subaction.type ?? "", onChange: { str in .atPath([index + 1, 4], .changeString(.type, str)) }, .isResponder(editor.atPath == [index + 1, 4])).height(1), .firstResponder([index + 1, 4]), .highlight(false)),
            Repeating(Text("─".foreground(.black))).height(1),
        ])
    ])
}
