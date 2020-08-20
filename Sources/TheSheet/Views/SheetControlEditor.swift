////
///  SheetControlEditor.swift
//

import Ashen

func SheetControlEditor(column: SheetColumn, control: SheetControl, controlIndex: Int, lastIndex: Int)
    -> View<SheetColumn.Message>
{
    let reorderControls: View<SheetColumn.Message>
    if column.canReorder {
        reorderControls = ReorderControls(controlIndex: controlIndex, lastIndex: lastIndex)
    } else {
        reorderControls = Space()
    }

    let removeControl: View<SheetColumn.Message>
    if column.canDelete {
        removeControl = OnLeftClick(
            Text("  X  ").aligned(.middleRight),
            .controlMessage(controlIndex, .delegate(.removeControl))
        ).background(view: Text(" ")).background(color: .red)
    } else {
        removeControl = Space()
    }

    let moveControl: View<SheetColumn.Message>
    if column.canDelete {
        moveControl = OnLeftClick(
            Text(" Move ").aligned(.middleRight),
            .controlMessage(controlIndex, .delegate(.moveControl))
        ).background(view: Text(" ")).background(color: .green)
    } else {
        moveControl = Space()
    }
    return Flow(
        .ltr,
        [
            (.fixed, reorderControls),
            (.fixed, moveControl),
            (.flex1, OnLeftClick(Space(), SheetColumn.Message.delegate(.stopEditing), .highlight(false))),
            (
                .fixed,
                control.isEditable
                    ? OnLeftClick(
                        Text(" Edit ").aligned(.middleRight)
                            .background(view: Text(" "))
                            .background(color: .blue),
                        SheetColumn.Message.delegate(.showControlEditor(controlIndex)))
                    : Space()
            ),
            (.fixed, IgnoreMouse(Repeating(Text(" "))).width(column.canDelete ? 1 : 0)),
            (.fixed, removeControl),
        ])
}

private func ReorderControls(controlIndex: Int, lastIndex: Int) -> View<SheetColumn.Message> {
    let canMoveUp = controlIndex > 0
    let canMoveDown = controlIndex < lastIndex
    return BasedOnSize { size in
        if size.height >= 3 {
            return Flow(
                .down,
                [
                    (
                        .flex1,
                        OnLeftClick(
                            Text("  ↑  ").aligned(.topCenter),
                            SheetColumn.Message.moveControl(controlIndex, .up)
                        ).background(view: Text(" "))
                            .background(color: canMoveUp ? .cyan : .black)
                    ),
                    (
                        .fixed,
                        IgnoreMouse(Repeating(Text(" "))).height((size.height % 2) == 0 ? 0 : 1)
                    ),
                    (
                        .flex1,
                        OnLeftClick(
                            Text("  ↓  ").aligned(
                                .bottomCenter), SheetColumn.Message.moveControl(controlIndex, .down)
                        ).background(view: Text(" "))
                            .background(color: canMoveDown ? .cyan : .black)
                    ),
                ]
            ).height(size.height)
        } else {
            return Stack(
                .ltr,
                [
                    (OnLeftClick(
                        Text("  ↑  ").aligned(.topCenter),
                        SheetColumn.Message.moveControl(controlIndex, .up)
                    ).background(view: Text(" "))
                        .background(color: canMoveUp ? .cyan : .black)),
                    (IgnoreMouse(Repeating(Text(" "))).width(1)),
                    (OnLeftClick(
                        Text("  ↓  ".background(canMoveDown ? .cyan : .black)).aligned(
                            .bottomCenter), SheetColumn.Message.moveControl(controlIndex, .down)
                    ).background(view: Text(" ".background(canMoveDown ? .cyan : .black)))),
                ])
        }
    }
}
