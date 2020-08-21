////
///  SheetControlEditor.swift
//

import Ashen

func SheetControlEditor(column: SheetColumn, control: SheetControl, controlIndex: Int, lastIndex: Int)
    -> View<SheetColumn.Message>
{
    var leftHandControls: [View<SheetColumn.Message>] = []
    var rightHandControls: [View<SheetColumn.Message>] = []

    if column.canReorder {
        leftHandControls.append(ReorderControls(controlIndex: controlIndex, lastIndex: lastIndex))
    }

    if control.canEdit {
        rightHandControls.append(OnLeftClick(
            Text(" Edit ").aligned(.middleRight)
                .background(view: Text(" "))
                .background(color: .blue),
            .delegate(.showControlEditor(controlIndex))))
    }

    if column.canDelete {
        leftHandControls.append(OnLeftClick(
                Text(" Move ").aligned(.middleRight),
                .delegate(.relocateControl(controlIndex))
            ).background(view: Text(" ")).background(color: .green))
        rightHandControls.append(IgnoreMouse(Repeating(Text(" "))).width(column.canDelete ? 1 : 0))
        rightHandControls.append(OnLeftClick(
                Text("  X  ").aligned(.middleRight),
                .controlMessage(controlIndex, .delegate(.removeControl))
            ).background(view: Text(" ")).background(color: .red))
    }

    return Flow(
        .ltr,
            leftHandControls.map { (.fixed, $0) } +
            [
                (.flex1, OnLeftClick(Space(), SheetColumn.Message.delegate(.stopEditing), .highlight(false)))
            ] +
            rightHandControls.map { (.fixed, $0) }
        )
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
