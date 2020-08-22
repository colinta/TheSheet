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
            OnLeftClick(Text("---".styled(action.level == nil ? .bold : .none)), EditableControl.Message.changeString(.level, "")),
        ] + levels.map { level in
            OnLeftClick(Text("[\(level)]".styled(action.level == level ? .bold : .none)), EditableControl.Message.changeString(.level, level))
                .padding(left: 1)
        })
    let descriptionEditors: [View<EditableControl.Message>] = [
        OnLeftClick(Text("Description:"), EditableControl.Message.firstResponder([0, 4]), .highlight(false)),
        OnLeftClick(
            Input(action.description ?? "", onChange: { EditableControl.Message.changeString(.description, $0) },
                .placeholder("(optional)"),
                .isResponder(editor.atPath == [0, 4]),
                .isMultiline(true)),
            EditableControl.Message.firstResponder([0, 4]), .highlight(false)
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
        + [
        ])
}

private func PromptInput(_ prompt: String, _ value: String?,
    _ property: EditableControl.Message.Property, path: IndexPath?, index: Int, placeholder: String = ""
) -> View<EditableControl.Message>
{
    OnLeftClick(
        Stack(.ltr, [
            Text(prompt),
            Input(value ?? "", onChange: { EditableControl.Message.changeString(property, $0) },
                .placeholder(placeholder), .isResponder(path == [0, index])),
        ]),
        EditableControl.Message.firstResponder([0, index]),
        .highlight(false)
    )
}
