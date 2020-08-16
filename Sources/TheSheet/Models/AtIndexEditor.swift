////
///  AtIndexEditor.swift
//

struct AtIndexEditor {
    let atIndex: Int?

    func replace(atIndex: Int) -> AtIndexEditor {
        AtIndexEditor(atIndex: atIndex)
    }

    func deselect() -> AtIndexEditor {
        AtIndexEditor(atIndex: nil)
    }
}
