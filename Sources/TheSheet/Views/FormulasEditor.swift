////
///  FormulasEditor.swift
//

import Ashen
import Foundation

func FormulasEditor(_ formulas: [Formula.Editable], editor: AtPathEditor) -> View<
    EditableControl.Message
> {
    let nextResponder: IndexPath
    if let xy = editor.atXY {
        if xy.x == 0 {
            nextResponder = [1, xy.y]
        } else {
            nextResponder = [0, (xy.y + 1) % formulas.count]
        }
    } else {
        nextResponder = [0, 0]
    }

    let enumeratedFormulas = formulas.enumerated()
    let variablesColumn = Stack(
        .down,
        enumeratedFormulas.map { index, formula in
            OnLeftClick(
                Input(
                    formula.variable,
                    onChange: { txt in
                        EditableControl.Message.atIndex(index, .changeString(.variable, txt))
                    }, .isResponder(editor.atXY.map { $0 == Point(x: 0, y: index) } ?? false)),
                EditableControl.Message.firstResponder(IndexPath(indexes: [0, index])),
                .highlight(false)
            )
        })
    let equalsColumn: View<EditableControl.Message> = Stack(
        .down,
        enumeratedFormulas.map { _ in
            Text(" = ")
        })
    let formulasColumn: View<EditableControl.Message> = Stack(
        .down,
        enumeratedFormulas.map { index, formula in
            let isResponder = editor.atXY.map { $0 == Point(x: 1, y: index) } ?? false
            return OnLeftClick(
                (isResponder
                    ? Input(
                        formula.editableFormula,
                        onChange: { txt in
                            EditableControl.Message.atIndex(index, .changeString(.operation, txt))
                        },
                        .isResponder(true))
                    : Text(formula.editableFormula)).foreground(
                        color: formula.toFormula() == nil ? .red : .none),
                EditableControl.Message.firstResponder(IndexPath(indexes: [1, index])),
                .highlight(false)
            )
        })
    let removeColumn: View<EditableControl.Message> = Stack(
        .down,
        enumeratedFormulas.map { index, _ in
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
                    (.fixed, variablesColumn),
                    (.fixed, equalsColumn),
                    (.flex1, formulasColumn),
                    (.fixed, removeColumn),
                ]),
            OnLeftClick(Text("[Add]").centered(), EditableControl.Message.add),
        ])
}
