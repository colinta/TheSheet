////
///  SheetColumn.swift
//

import Ashen

struct SheetColumn {
    enum Message {
        case control(Int, SheetControl.Message)
    }

    let title: String
    var controls: [SheetControl]

    func update(_ message: Message) -> SheetColumn {
        switch message {
        case let .control(changeIndex, message):
            return SheetColumn(
                title: title,
                controls: controls.enumerated().map { index, control in
                    guard index == changeIndex else { return control }
                    return control.update(message)
                })
        }
    }

    func render() -> View<SheetColumn.Message> {
        Stack(
            .down,
            controls.enumerated().map { index, control in
                control.render().map { SheetColumn.Message.control(index, $0) }.padding(bottom: 1)
            }
        ).border(
            .single, .title(title.bold()), .alignment(.topLeft)
        )
    }
}
