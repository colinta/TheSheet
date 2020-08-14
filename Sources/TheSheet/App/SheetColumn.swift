////
///  SheetColumn.swift
//

import Ashen

struct SheetColumn: Codable {
    enum Message {
        case control(Int, SheetControl.Message)
        case moveControl(Int, MouseEvent.Direction)
        case stopEditing
    }

    let title: String
    let controls: [SheetControl]
    let isFormulaColumn: Bool

    init(title: String, controls: [SheetControl], isFormulaColumn: Bool = true) {
        self.title = title
        self.controls = controls
        self.isFormulaColumn = isFormulaColumn
    }

    var formulas: [Formula] {
        Operation.mergeAll(controls.map(\.formulas))
    }

    var canEdit: Bool { !isFormulaColumn }
    var canDelete: Bool { !isFormulaColumn }
    var canAdd: Bool { !isFormulaColumn }

    func replace(title: String) -> SheetColumn {
        SheetColumn(
            title: title,
            controls: controls,
            isFormulaColumn: isFormulaColumn)
    }

    func replace(controls: [SheetControl]) -> SheetColumn {
        SheetColumn(
            title: title,
            controls: controls,
            isFormulaColumn: isFormulaColumn)
    }

    func update(_ message: Message) -> (SheetColumn, Sheet.Mod?) {
        switch message {
        case .stopEditing:
            return (self, nil)
        case let .moveControl(controlIndex, direction):
            let newIndex = direction == .up ? controlIndex - 1 : controlIndex + 1
            guard controlIndex >= 0, controlIndex < controls.count,
                newIndex >= 0, newIndex <= controls.count
            else { return (self, nil) }

            let control = self.controls[controlIndex]
            var controls = self.controls
            controls.remove(at: controlIndex)
            controls.insert(control, at: newIndex)
            return (replace(controls: controls), nil)
        case let .control(controlIndex, .removeControl):
            guard controlIndex >= 0, controlIndex < controls.count else { return (self, nil) }
            var controls = self.controls
            controls.remove(at: controlIndex)
            return (replace(controls: controls), nil)
        case let .control(changeIndex, message):
            var mod: Sheet.Mod? = nil
            let controls = self.controls.enumerated().map { (index, control) -> SheetControl in
                guard index == changeIndex else { return control }
                let (newControl, newMod) = control.update(message)
                mod = newMod
                return newControl
            }
            return (replace(controls: controls), mod)
        }
    }

    func render(_ sheet: Sheet, isEditing: Bool) -> View<SheetColumn.Message> {
        Stack(
            .down,
            controls.enumerated().flatMap { index, control -> [View<SheetColumn.Message>] in
                let controlView = control.render(sheet).map {
                    SheetColumn.Message.control(index, $0)
                }.matchContainer(dimension: .width)
                let editableControlView: View<SheetColumn.Message>
                if isEditing {
                    editableControlView = ZStack([
                        controlView,
                        editingControls(control, index: index, lastIndex: controls.count - 1)
                            .matchSize(ofView: controlView),
                    ])
                } else {
                    editableControlView = controlView
                }

                return [
                    editableControlView,
                    Repeating(Text("─".foreground(.black))).height(1),
                ]
            }
        )
    }

    private func editingControls(_ control: SheetControl, index: Int, lastIndex: Int) -> View<SheetColumn.Message> {
        let canMoveUp = index > 0
        let canMoveDown = index < lastIndex
        return Flow(
            .ltr,
            [
                (.fixed, BasedOnSize { size in
                    if size.height >= 3 {
                        return Flow(.down, [
                            (
                                .flex1,
                                OnLeftClick(
                                    Text("  ↑  ".background(canMoveUp ? .cyan : .black)).aligned(.topCenter),
                                    Message.moveControl(index, .up)
                                ).background(view: Text(" ".background(canMoveUp ? .cyan : .black)))
                            ),
                            (.fixed, IgnoreMouse(Repeating(Text(" "))).height((size.height % 2) == 0 ? 2 : 1)),
                            (
                                .flex1,
                                OnLeftClick(
                                    Text("  ↓  ".background(canMoveDown ? .cyan : .black)).aligned(
                                        .bottomCenter), Message.moveControl(index, .down)
                                ).background(view: Text(" ".background(canMoveDown ? .cyan : .black)))
                            ),
                        ]).height(size.height)
                    }
                    else {
                        return Stack(.ltr, [
                            (
                                OnLeftClick(
                                    Text("  ↑  ".background(canMoveUp ? .cyan : .black)).aligned(.middleRight),
                                    Message.moveControl(index, .up)
                                ).background(view: Text(" ".background(canMoveUp ? .cyan : .black)))
                            ),
                            (IgnoreMouse(Repeating(Text(" "))).width(1)),
                            (
                                OnLeftClick(
                                    Text("  ↓  ".background(canMoveDown ? .cyan : .black)).aligned(
                                        .middleRight), Message.moveControl(index, .down)
                                ).background(view: Text(" ".background(canMoveDown ? .cyan : .black)))
                            ),
                        ])
                    }
                }),
                (.flex1, OnLeftClick(Space(), Message.stopEditing, .highlight(false))),
                (
                    .fixed,
                    control.isEditable
                    ? (Text(" Edit ".background(.blue)).aligned(.middleRight)).background(
                        view: Text(" ".background(.blue)))
                    : Space()
                ),
                (.fixed, IgnoreMouse(Repeating(Text(" "))).width(1)),
                (
                    .fixed,
                    OnLeftClick(
                        Text("  X  ".background(.red)).aligned(.middleRight),
                        Message.control(index, .removeControl)
                    ).background(view: Text(" ".background(.red)))
                ),
            ])
    }
}
