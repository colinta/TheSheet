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
    var controls: [SheetControl]
    var formulas: Formula.Lookup {
        Formula.mergeAll(controls.map(\.formulas))
    }

    func replace(title: String) -> SheetColumn {
        SheetColumn(
            title: title,
            controls: controls)
    }

    func replace(controls: [SheetControl]) -> SheetColumn {
        SheetColumn(
            title: title,
            controls: controls)
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
                }
                .matchContainer(.width)
                let editableControlView: View<SheetColumn.Message>
                if isEditing {
                    editableControlView = ZStack([
                        controlView,
                        editingControls(index: index, lastIndex: controls.count - 1),
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

    private func editingControls(index: Int, lastIndex: Int) -> View<SheetColumn.Message> {
        let canMoveUp = index > 0
        let canMoveDown = index < lastIndex
        return Flow(
            .ltr,
            [
                (
                    .fixed,
                    OnLeftClick(
                        Text("  ↑  ".background(canMoveUp ? .cyan : .black)).aligned(.middleRight),
                        Message.moveControl(index, .up)
                    ).background(view: Text(" ".background(canMoveUp ? .cyan : .black)))
                ),
                (.fixed, IgnoreMouse(Repeating(Text(" "))).width(1)),
                (
                    .fixed,
                    OnLeftClick(
                        Text("  ↓  ".background(canMoveDown ? .cyan : .black)).aligned(
                            .middleRight), Message.moveControl(index, .down)
                    ).background(view: Text(" ".background(canMoveDown ? .cyan : .black)))
                ),
                (.flex1, OnLeftClick(Space(), Message.stopEditing, .highlight(false))),
                (
                    .fixed,
                    (Text(" Edit ".background(.blue)).aligned(.middleRight)).background(
                        view: Text(" ".background(.blue)))
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
