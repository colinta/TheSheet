////
///  AtPathEditor.swift
//

import Ashen
import Foundation

struct AtPathEditor {
    let atPath: IndexPath?
    var atXY: Point? {
        atPath.map { Point(x: $0[0], y: $0[1])}
    }

    func replace(path: IndexPath) -> AtPathEditor {
        AtPathEditor(atPath: path)
    }

    func replace(index: Int) -> AtPathEditor {
        AtPathEditor(atPath: [index])
    }

    func replace(x: Int, y: Int) -> AtPathEditor {
        AtPathEditor(atPath: [x, y])
    }

    func deselect() -> AtPathEditor {
        AtPathEditor(atPath: nil)
    }
}
