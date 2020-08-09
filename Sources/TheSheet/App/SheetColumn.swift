////
///  SheetColumn.swift
//

import Ashen

struct SheetColumn: Codable {
    enum Message {
        case control(Int, SheetControl.Message)
    }

    let title: String
    var controls: [SheetControl]

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
        case let .control(changeIndex, .removeControl):
            let controls = self.controls.enumerated().compactMap {
                (index, control) -> SheetControl? in
                guard index == changeIndex else { return control }
                return nil
            }
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
                        editingControls(index: index),
                        controlView,
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

    private func editingControls(index: Int) -> View<SheetColumn.Message> {
        Flow(
            .ltr,
            [
                (
                    .fixed,
                    Text("  ↑  ".background(.cyan)).aligned(.middleRight).background(
                        view: Text(" ".background(.cyan)))
                ),
                (.fixed, ClaimMouse(Repeating(Text(" "))).width(1)),
                (
                    .fixed,
                    Text("  ↓  ".background(.cyan)).aligned(.middleRight).background(
                        view: Text(" ".background(.cyan)))
                ),
                (.flex1, ClaimMouse(Space())),
                (
                    .fixed,
                    Text(" Edit ".background(.blue)).aligned(.middleRight).background(
                        view: Text(" ".background(.blue)))
                ),
                (.fixed, ClaimMouse(Repeating(Text(" "))).width(1)),
                (
                    .fixed,
                    OnLeftClick(
                        Text("  X  ".background(.red)).aligned(.middleRight).background(
                            view: Text(" ".background(.red))),
                        Message.control(index, .removeControl))
                ),
            ])
    }
}
