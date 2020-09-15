////
///  JournalEditor.swift
//

import Ashen

func JournalEditor(journal: Journal, editor: AtPathEditor) -> View<EditableControl.Message> {
    Stack(
        .ltr,
        [
            Stack(
                .down,
                [
                    OnLeftClick(Text("Title:"), .firstResponder([0]), .highlight(false)),
                    OnLeftClick(Text("Journal:"), .firstResponder([1]), .highlight(false)),
                ]
            ).padding(right: 1),
            Stack(
                .down,
                [
                    OnLeftClick(
                        Input(
                            journal.title, onChange: { .changeString(.title, $0) },
                            .isResponder(editor.atPath == [0]), .placeholder("Title")),
                        .firstResponder([0]), .highlight(false)),
                    OnLeftClick(
                        Input(
                            journal.text, onChange: { .changeString(.text, $0) },
                            .isResponder(editor.atPath == [1]),
                            .isMultiline(true),
                            .wrap(true),
                            .placeholder("Journal")), .firstResponder([1]), .highlight(false)),
                ]),
        ])
}
