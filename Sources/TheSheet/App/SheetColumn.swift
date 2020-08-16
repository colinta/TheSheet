////
///  SheetColumn.swift
//

import Ashen

struct SheetColumn: Codable {
    enum Message {
        enum Delegate {
            case showControlEditor(Int)
            case stopEditing
        }
        case controlMessage(Int, SheetControl.Message)
        case moveControl(Int, MouseEvent.Direction)
        case delegate(Delegate)
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

    var canReorder: Bool { !isFormulaColumn }
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
        case .delegate:
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
        case let .controlMessage(controlIndex, .delegate(.removeControl)):
            guard controlIndex >= 0, controlIndex < controls.count else { return (self, nil) }
            var controls = self.controls
            controls.remove(at: controlIndex)
            return (replace(controls: controls), nil)
        case let .controlMessage(changeIndex, message):
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

    func render(_ sheet: Sheet, isEditing: Bool, editingControl: Int?) -> View<SheetColumn.Message> {
        Stack(
            .down,
            controls.enumerated().flatMap { controlIndex, control -> [View<SheetColumn.Message>] in
                let controlView = control.render(sheet).map {
                    SheetColumn.Message.controlMessage(controlIndex, $0)
                }.matchContainer(dimension: .width)
                let editableControlView: View<SheetColumn.Message>
                if isEditing {
                    editableControlView = ZStack([
                        controlView,
                        editingControls(control, controlIndex: controlIndex, lastIndex: controls.count - 1)
                            .matchSize(ofView: controlView),
                    ])
                } else if editingControl == controlIndex {
                    editableControlView = controlView.reversed()
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

    private func editingControls(_ control: SheetControl, controlIndex: Int, lastIndex: Int) -> View<SheetColumn.Message> {
        let reorderControls: View<SheetColumn.Message>
        if canReorder {
            reorderControls = self.reorderControls(controlIndex: controlIndex, lastIndex: lastIndex)
        }
        else {
            reorderControls = Space()
        }
        let removeControl: View<SheetColumn.Message>
        if canDelete {
            removeControl = OnLeftClick(
                Text("  X  ").aligned(.middleRight),
                Message.controlMessage(controlIndex, .delegate(.removeControl))
            ).background(view: Text(" ")).background(color: .red)
        }
        else {
            removeControl = Space()
        }
        return Flow(
            .ltr,
            [
                (.fixed, reorderControls),
                (.flex1, OnLeftClick(Space(), Message.delegate(.stopEditing), .highlight(false))),
                (
                    .fixed,
                    control.isEditable
                    ? OnLeftClick(
                        Text(" Edit ").aligned(.middleRight)
                            .background(view: Text(" "))
                            .background(color: .blue),
                        Message.delegate(.showControlEditor(controlIndex)))
                    : Space()
                ),
                (.fixed, IgnoreMouse(Repeating(Text(" "))).width(canDelete ? 1 : 0)),
                (.fixed, removeControl),
            ])
    }

    private func reorderControls(controlIndex: Int, lastIndex: Int) -> View<SheetColumn.Message> {
        let canMoveUp = controlIndex > 0
        let canMoveDown = controlIndex < lastIndex
        return BasedOnSize { size in
            if size.height >= 3 {
                return Flow(.down, [
                    (
                        .flex1,
                        OnLeftClick(
                            Text("  ↑  ").aligned(.topCenter),
                            Message.moveControl(controlIndex, .up)
                        ).background(view: Text(" "))
                        .background(color: canMoveUp ? .cyan : .black)
                    ),
                    (.fixed, IgnoreMouse(Repeating(Text(" "))).height((size.height % 2) == 0 ? 0 : 1)),
                    (
                        .flex1,
                        OnLeftClick(
                            Text("  ↓  ").aligned(
                                .bottomCenter), Message.moveControl(controlIndex, .down)
                        ).background(view: Text(" "))
                        .background(color: canMoveDown ? .cyan : .black)
                    ),
                ]).height(size.height)
            }
            else {
                return Stack(.ltr, [
                    (
                        OnLeftClick(
                            Text("  ↑  ").aligned(.topCenter),
                            Message.moveControl(controlIndex, .up)
                        ).background(view: Text(" "))
                        .background(color: canMoveUp ? .cyan : .black)
                    ),
                    (IgnoreMouse(Repeating(Text(" "))).width(1)),
                    (
                        OnLeftClick(
                            Text("  ↓  ".background(canMoveDown ? .cyan : .black)).aligned(
                                .bottomCenter), Message.moveControl(controlIndex, .down)
                        ).background(view: Text(" ".background(canMoveDown ? .cyan : .black)))
                    ),
                ])
            }
        }
    }
}
