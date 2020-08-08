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

    func render(_ sheet: Sheet) -> View<SheetColumn.Message> {
        Stack(
            .down,
            controls.enumerated().flatMap { index, control in
                [
                    control.render(sheet).map { SheetColumn.Message.control(index, $0) }
                        .matchParent(.width),
                    Repeating(Text("─".foreground(.black))).height(1),
                ]
            }
        )
    }
}
