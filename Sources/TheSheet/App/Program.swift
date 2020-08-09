////
///  Program.swift
//

import Ashen
import Foundation

enum Message {
    case sheet(Sheet.Message)
    case changeColumn(Int)
    case editColumn(Int?)
    case addControl(Int?)
    case replaceColumn(at: Int, with: Int)
    case scroll(Int)
    case setScrollSize(Int, LocalViewport)
    case undo
    case reloadJSON
    case statusDidTimeout
    case saveJSON
    case quit
}

func initial(sheet: Sheet, fileURL: URL?) -> () -> Initial<Model, Message> {
    return {
        Initial(
            Model(sheet: sheet, fileURL: fileURL))
    }
}

func showStatus(model: Model, status: String?) -> State<Model, Message> {
    if let status = status {
        return .update(
            model.replace(status: status),
            [Timeout(STATUS_TIMEOUT, Message.statusDidTimeout)])
    } else {
        return .model(model.replace(status: nil))
    }
}

func update(model: inout Model, message: Message) -> State<Model, Message> {
    switch message {
    case .sheet(.column(_, .stopEditing)):
        return .model(model.replace(editColumn: nil))
    case let .sheet(message):
        return .model(model.replace(sheet: model.sheet.update(message)))
    case let .changeColumn(index):
        guard model.changeColumn != index else {
            return .model(model.replace(changeColumn: nil))
        }
        return .model(model.replace(changeColumn: index))
    case let .editColumn(index):
        guard model.editColumn != index else {
            return .model(model.replace(editColumn: nil))
        }
        return .model(model.replace(editColumn: index))
    case let .addControl(index):
        return .model(model.replace(addingToColumn: index))
    case let .setScrollSize(index, scrollViewport):
        return .model(model.replace(column: index, scrollViewport: scrollViewport))
    case let .replaceColumn(oldIndex, columnIndex):
        guard columnIndex >= 0, columnIndex < model.sheet.columns.count else { return .noChange }

        return .model(
            model.replace(
                sheet: model.sheet.replace(
                    selectedColumns: model.sheet.selectedColumns.enumerated().map {
                        position, index in
                        if position == oldIndex {
                            return columnIndex
                        } else {
                            return index
                        }
                    })))
    case let .scroll(delta):
        guard
            let maxOffset = model.columnScrollMaxOffsets.values.reduce(
                nil as Int?,
                { memo, height in
                    max(memo ?? 0, height)
                })
        else { return .noChange }
        let scrollOffset = max(0, min(model.scrollOffset + delta, maxOffset))
        return .model(model.replace(scrollOffset: scrollOffset))
    case .undo:
        return .model(model.undo())
    case .reloadJSON:
        guard let fileURL = model.fileURL else {
            return showStatus(model: model, status: "No JSON file to reload")
        }

        if let data = try? String(contentsOf: fileURL).data(using: .utf8) {
            let coder = JSONDecoder()
            if let sheet = try? coder.decode(Sheet.self, from: data) {
                return showStatus(model: model.replace(sheet: sheet), status: "JSON Reloaded")
            }
        }

        return showStatus(model: model, status: "Error reloading JSON")
    case .saveJSON:
        guard let fileURL = model.fileURL else {
            return showStatus(model: model, status: "No JSON file to save")
        }

        let coder = JSONEncoder()
        coder.outputFormatting = .prettyPrinted
        do {
            let data = try coder.encode(model.sheet)
            try data.write(to: fileURL, options: [.atomic])
            return showStatus(model: model, status: "JSON Saved")
        } catch {
            return showStatus(model: model, status: "Error saving JSON")
        }
    case .statusDidTimeout:
        let now = Date().timeIntervalSince1970
        if let timeout = model.status?.timeout, timeout > now {
            return .update(
                model,
                [Timeout(timeout - now + 0.01, Message.statusDidTimeout)])
        }

        return .model(model.replace(status: nil))
    case .quit:
        return .quit
    }
}

func render(model: Model) -> [View<Message>] {
    _render(model, status: model.status.map { $0.0 })
}

private func _render(_ model: Model, status: String?) -> [View<Message>] {
    ([
        OnKeyPress(key: .up, Message.scroll(-1)),
        OnKeyPress(key: .down, Message.scroll(1)),
        OnKeyPress(key: .pageUp, Message.scroll(-25)),
        OnKeyPress(key: .pageDown, Message.scroll(25)),
        OnKeyPress(key: .space, Message.scroll(25)),
        OnKeyPress(key: .esc, Message.quit),
        OnKeyPress(key: .ctrl(.s), Message.saveJSON),
        OnKeyPress(key: .ctrl(.o), Message.reloadJSON),
        OnKeyPress(key: .ctrl(.z), Message.undo),
        model.addingToColumn == nil ? OnMouseWheel(Space(), Message.scroll) : nil,
        Flow(
            .down,
            [
                (.fixed, Text("The Sheet").height(1).centered().bold()),
                (
                    .flex1,
                    Columns(
                        model.sheet.selectedColumns.enumerated().compactMap { position, index in
                            guard index >= 0 && index < model.sheet.columns.count else {
                                return nil
                            }
                            let column = model.sheet.columns[index]
                            let columnView = column.render(
                                model.sheet, isEditing: model.editColumn == position)
                            return ZStack(
                                [
                                    Scroll(
                                        columnView.map {
                                            Message.sheet(Sheet.Message.column(index, $0))
                                        }.fitInContainer(.width),
                                        onResizeContent: { scrollViewport in
                                            Message.setScrollSize(index, scrollViewport)
                                        },
                                        .offset(y: model.scrollOffset)
                                    ).border(
                                        .single, .title(column.title.bold()),
                                        .alignment(.topLeft)
                                    )

                                ] + renderColumnEditor(model, position)
                            )
                        }
                    )
                ),
                (
                    .fixed,
                    MainButtons(model: model, status: status)
                ),
            ]),
        model.addingToColumn != nil ? renderControlEditor() : nil,
    ] as [View<Message>?]).compactMap { $0 }
}

func renderControlEditor() -> View<Message> {
    ZStack([
        IgnoreMouse(),
        OnLeftClick(
            Space().modifyCharacters { pt, size, c in
                return AttributedCharacter(
                    character: AttributedCharacter.null.character, attributes: []
                ).styled(.foreground(.black)).styled(.background(.none))
            }, Message.addControl(nil), .highlight(false)),
    ])
}

func renderColumnEditor(_ model: Model, _ position: Int) -> [View<Message>] {
    guard model.sheet.columns.count > model.sheet.selectedColumns.count else { return [] }
    let current = model.sheet.selectedColumns[position]
    if model.changeColumn == position {
        return [
            Box(
                Stack(
                    .down,
                    model.sheet.columns.enumerated().map { newIndex, column in
                        OnLeftClick(
                            newIndex == current ? Text(column.title.bold()) : Text(column.title),
                            Message.replaceColumn(at: position, with: newIndex))
                    }
                )
            ).background(view: Text(" ")).aligned(.topRight),
            OnLeftClick(Text("[x]").reversed(), Message.changeColumn(position)).compact().padding(
                right: 1
            ).aligned(.topRight),
        ]
    } else {
        let isEditing = model.editColumn == position
        let isAdding = model.addingToColumn == position
        return [
            Stack(
                .rtl,
                [
                    OnLeftClick(
                        Text("[…]"), Message.changeColumn(position)
                    ).padding(right: 1).compact(),
                    OnLeftClick(
                        Text("[Edit]".styled(isEditing ? .reverse : .none)),
                        Message.editColumn(position)
                    ).padding(right: 1).compact(),
                    OnLeftClick(
                        Text("[Add]".styled(isAdding ? .reverse : .none)),
                        Message.addControl(position)
                    ).padding(right: 1).compact(),
                ])

        ]
    }
}

func MainButtons(model: Model, status: String?) -> View<Message> {
    let buttons: [View<Message>] = [
        OnLeftClick(
            Text("Undo".foreground(model.canUndo ? .none : .black))
                .underlined()
                .padding(left: 1, right: 1)
                .border(.single), Message.undo, .isEnabled(model.canUndo)),
        OnLeftClick(
            Text("Reload")
                .underlined()
                .padding(left: 1, right: 1)
                .border(.single), Message.reloadJSON),
        OnLeftClick(
            Text("Save")
                .underlined()
                .padding(left: 1, right: 1)
                .border(.single),
            Message.saveJSON),
        OnLeftClick(
            Text("Exit")
                .underlined()
                .padding(left: 1, right: 1)
                .border(.single),
            Message.quit),

    ]
    return Flow(
        .ltr,
        [
            (.fixed, status.map { Text($0).aligned(.middleCenter) } ?? Space()),
            (.flex1, Space()),
        ]
            + buttons.flatMap { button in
                [(.fixed, button), (.fixed, Space().width(1))]
            }
    )
}
