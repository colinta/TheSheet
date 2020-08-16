////
///  AtXYEditor.swift
//

import Ashen

struct AtXYEditor {
    let atXY: Point?

    func replace(x: Int, y: Int) -> AtXYEditor {
        AtXYEditor(atXY: Point(x: x, y: y))
    }

    func deselect() -> AtXYEditor {
        AtXYEditor(atXY: nil)
    }
}
