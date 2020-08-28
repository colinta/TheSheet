////
///  JournalEditor.swift
//

import Ashen

func JournalEditor(journal: (String, String), editor: AtPathEditor) -> View<EditableControl.Message> {
    Stack(.ltr, [
        Stack(.down, [
            OnLeftClick(Text("Title:"), .firstResponder([0]), .highlight(false)),
            OnLeftClick(Text("Journal:"), .firstResponder([1]), .highlight(false)),
        ]).padding(right: 1),
        Stack(.down, [
            OnLeftClick(Input(journal.0, onChange: { .changeString(.title, $0) }, .isResponder(editor.atPath == [0]), .placeholder("Title")), .firstResponder([0]), .highlight(false)),
            OnLeftClick(Input(journal.1, onChange: { .changeString(.journal, $0) }, .isResponder(editor.atPath == [1]), .isMultiline(true), .placeholder("Journal")), .firstResponder([1]), .highlight(false)),
        ]),
    ])
}
