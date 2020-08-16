////
///  Program.swift
//

import Ashen
import Foundation

enum Message {
    case sheet(Sheet.Message)
    case advanceVisibleColumn(Int)
    case changeVisibleColumnsCount(Int)
    case changeColumn(Int)
    case editColumn(Int)
    case startAddControl(Int)
    case addControl(SheetControl, to: Int)
    case replaceColumn(at: Int, with: Int)
    case cancelModal
    case scrollColumns(Int)
    case scrollModal(Int)
    case setColumnScrollSize(Int, LocalViewport)
    case setModalScrollSize(LocalViewport)
    case undo
    case reloadJSON
    case statusDidTimeout
    case saveJSON
    case quit
}

func initial(sheet: Sheet, fileURL: URL?) -> () -> Initial<Model, Message> {
    // let command: Command<Message> = HttpRequest.get(url: "https://www.dnd5eapi.co/api/spells/acid-arrow/")
    //     .decodeJson(Dnd5eSpell.self)
    //     .start(onComplete: Message.httpResult)
    return {
        Initial(
            Model(sheet: sheet, fileURL: fileURL),
            commands: []
        )
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
    case let .sheet(.columnMessage(columnIndex, .delegate(delegate))):
        switch delegate {
        case let .showControlEditor(controlIndex):
            let restore = model.sheet.columns[columnIndex].controls[controlIndex]
            return .model(model.replace(editControl: controlIndex, inColumn: columnIndex, restore: restore))
        case .stopEditing:
            return .model(model.stopEditing())
        }
    case let .sheet(message):
        return .model(model.replace(sheet: model.sheet.update(message)))
    case let .advanceVisibleColumn(delta):
        let firstIndex = model.firstVisibleColumn + delta
        let lastIndex = model.firstVisibleColumn + delta + model.sheet.visibleColumnsCount
        guard firstIndex >= 0,
            lastIndex <= model.sheet.columns.count
        else { return .noChange }
        return .model(model.replace(firstVisibleColumn: model.firstVisibleColumn + delta))
    case let .changeVisibleColumnsCount(delta):
        let newCount = model.sheet.visibleColumnsCount + delta
        guard newCount > 0,
            newCount <= model.sheet.columns.count
        else { return .noChange }
        return .model(
            model.replace(
                sheet: model.sheet.replace(visibleColumnsCount: newCount)))
    case let .changeColumn(index):
        guard !model.isChangingColumn(index) else {
            return .model(model.stopEditing())
        }
        return .model(model.replace(changeColumn: index))
    case let .editColumn(index):
        guard !model.isEditingColumn(index) else {
            return .model(model.stopEditing())
        }
        return .model(model.replace(editColumn: index))
    case let .startAddControl(index):
        return .model(model.replace(addToColumn: index))
    case let .addControl(control, changeIndex):
        guard changeIndex >= 0, changeIndex < model.sheet.columns.count else { return .noChange }
        return .model(
            model.replace(
                sheet:
                    model.sheet.replace(
                        columns: model.sheet.columns.enumerated().map { index, column in
                            guard index == changeIndex else { return column }
                            return column.replace(controls: column.controls + [control])
                        })
            ).stopEditing())
    case let .replaceColumn(oldIndex, newIndex):
        guard newIndex >= 0, newIndex < model.sheet.columns.count else { return .noChange }
        return .model(
            model.replace(
                sheet: model.sheet.replace(
                    columnsOrder: model.sheet.columnsOrder.map {
                        index in
                        if index == oldIndex {
                            return newIndex
                        } else if index == newIndex {
                            return oldIndex
                        } else {
                            return index
                        }
                    }))
                .replace(changeColumn: newIndex)
            )
    case .cancelModal:
        return .model(model.stopEditing())
    case let .scrollColumns(delta):
        let scrollOffset = max(0, min(model.columnScrollOffset + delta, model.columnScrollMaxOffset))
        return .model(model.replace(columnScrollOffset: scrollOffset))
    case let .setColumnScrollSize(index, scrollViewport):
        return .model(model.replace(column: index, scrollViewport: scrollViewport))
    case let .setModalScrollSize(scrollViewport):
        return .model(model.replace(modalScrollViewport: scrollViewport))
    case let .scrollModal(delta):
        let scrollOffset = max(0, min(model.modalScrollOffset + delta, model.modalScrollMaxOffset))
        return .model(model.replace(modalScrollOffset: scrollOffset))
    case .undo:
        return .model(model.undo())
    case .reloadJSON:
        guard let fileURL = model.fileURL else {
            return showStatus(model: model, status: "No JSON file to reload")
        }

        if let data = try? String(contentsOf: fileURL).data(using: .utf8) {
            let coder = JSONDecoder()
            if let sheet = try? coder.decode(Sheet.self, from: data) {
                return showStatus(
                    model: model.stopEditing()
                        .replace(sheet: sheet),
                    status: "JSON Reloaded")
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
        guard let fileURL = model.fileURL else {
            return .quit
        }

        let coder = JSONEncoder()
        coder.outputFormatting = .prettyPrinted
        do {
            let data = try coder.encode(model.sheet)
            try data.write(to: fileURL, options: [.atomic])
            return .quit
        } catch {
            return showStatus(model: model, status: "Error saving JSON")
        }
    }
}

func render(model: Model) -> [View<Message>] {
    _render(model, status: model.status.map { $0.0 })
}

private func _render(_ model: Model, status: String?) -> [View<Message>] {
    ([
        OnKeyPress(key: .up, Message.scrollColumns(-1)),
        OnKeyPress(key: .down, Message.scrollColumns(1)),
        OnKeyPress(key: .left, Message.advanceVisibleColumn(-1)),
        OnKeyPress(key: .right, Message.advanceVisibleColumn(1)),
        OnKeyPress(key: .pageUp, Message.scrollColumns(-25)),
        OnKeyPress(key: .pageDown, Message.scrollColumns(25)),
        OnKeyPress(key: .space, Message.scrollColumns(25)),
        OnKeyPress(key: .esc, Message.quit),
        OnKeyPress(key: .ctrl(.s), Message.saveJSON),
        OnKeyPress(key: .ctrl(.o), Message.reloadJSON),
        OnKeyPress(key: .ctrl(.z), Message.undo),
        Flow(
            .down,
            [
                (.fixed, Text("The Sheet").height(1).centered().bold()),
                (
                    .flex1,
                    Columns(
                        model.sheet.columnsOrder[
                            model.firstVisibleColumn..<(model.sheet.visibleColumnsCount
                                + model.firstVisibleColumn)
                        ].compactMap { index in
                            guard index >= 0 && index < model.sheet.columns.count else {
                                return nil
                            }
                            let column = model.sheet.columns[index]
                            return renderColumn(
                                model, column,
                                columnIndex: index)
                        }
                    )
                ),
                (
                    .fixed,
                    MainButtons(model: model, status: status)
                ),
            ]),
        !(model.isAddingToColumn() || model.isEditingControl()) ? OnMouseWheel(Space(), Message.scrollColumns) : nil,
        model.editingControl.map({ column, control in renderControlEditor(model: model, column: column, control: control) }),
        model.addingToColumn.map({ renderControlSelector(model: model, addToColumn: $0) }),
    ] as [View<Message>?]).compactMap { $0 }
}

func inModal(model: Model, _ view: View<Message>) -> View<Message> {
    ZStack([
        IgnoreMouse(),
        OnLeftClick(
            Space().modifyCharacters { pt, size, c in
                return AttributedCharacter(
                    character: AttributedCharacter.null.character, attributes: []
                ).styled(.foreground(.black)).styled(.background(.none))
            }, Message.cancelModal, .highlight(false)),
        Scroll(
            view,
            onResizeContent: { scrollViewport in
                Message.setModalScrollSize(scrollViewport)
            },
            .offset(y: model.modalScrollOffset)
        ).border(
            .single
        )
            .minWidth(75, fittingContainer: true)
            .background(view: Text(" "))
            .aligned(.middleCenter),
        OnMouseWheel(Space(), Message.scrollModal)
    ])
}

func renderControlSelector(model: Model, addToColumn: Int) -> View<Message> {
    inModal(model: model, Stack(
        .down,
        SheetControl.allControls.map({ title, control in
            OnLeftClick(Text("[+] \(title)"), Message.addControl(control, to: addToColumn))
        })))
}

func renderControlEditor(model: Model, column columnIndex: Int, control controlIndex: Int) -> View<Message> {
    let column = model.sheet.columns[columnIndex]
    let control = column.controls[controlIndex]
    return inModal(model: model, control.editor(model.sheet)
        .map { SheetColumn.Message.controlEditingMessage(controlIndex, $0) }
        .map { Sheet.Message.columnMessage(columnIndex, $0) }
        .map { Message.sheet($0) })
}

func renderColumn(_ model: Model, _ column: SheetColumn, columnIndex: Int) -> View<Message> {
    let columnView = column.render(
        model.sheet,
        isEditing: model.isEditingColumn(columnIndex),
        editingControl: model.editingControl.flatMap({ $0.column == columnIndex ? $0.control : nil })
        )
    return ZStack(
        [
            Scroll(
                columnView.map {
                    Message.sheet(Sheet.Message.columnMessage(columnIndex, $0))
                }.fitInContainer(dimension: .width),
                onResizeContent: { scrollViewport in
                    Message.setColumnScrollSize(columnIndex, scrollViewport)
                },
                .offset(y: model.columnScrollOffset)
            ).border(
                .single, .title(column.title.bold())
            )
        ] + renderColumnEditor(model, columnIndex)
    )
}

func renderColumnEditor(_ model: Model, _ columnIndex: Int) -> [View<Message>] {
    let currentColumn = model.sheet.columns[columnIndex]

    let isChanging = model.isChangingColumn(columnIndex)
    let isEditing = model.isEditingColumn(columnIndex)
    let isAdding = model.isAddingToColumn(columnIndex)

    let changeButton = OnLeftClick(
        Text("[…]".styled(isChanging ? .reverse : .none)), Message.changeColumn(columnIndex)
    ).padding(right: 1).compact()
    let editButton = OnLeftClick(
        Text("[Edit]".styled(isEditing ? .reverse : .none)),
        Message.editColumn(columnIndex)
    ).padding(right: 1).compact()
    let addButton = OnLeftClick(
        Text("[Add]".styled(isAdding ? .reverse : .none)),
        Message.startAddControl(columnIndex)
    ).padding(right: 1).compact()

    let buttons = Stack(
        .rtl,
        [
            changeButton,
            currentColumn.canEdit ? editButton : nil,
            currentColumn.canAdd ? addButton : nil,
        ].compactMap { $0 }
    )

    if isChanging {
        return [
            Box(
                Stack(
                    .down,
                    model.sheet.columns.enumerated().map { newIndex, column in
                        OnLeftClick(
                            newIndex == columnIndex ? Text(column.title.bold()) : Text(column.title),
                            Message.replaceColumn(at: columnIndex, with: newIndex))
                    }
                )
            ).background(view: Text(" ")).aligned(.topRight),
            buttons,
        ]
    } else {
        return [
            buttons
        ]
    }
}

func MainButtons(model: Model, status: String?) -> View<Message> {
    let columnCountControls = Stack(
        .ltr,
        [
            Text("Visible Columns: ").padding(top: 1),
            Stack(
                .down,
                [
                    OnLeftClick(
                        Text("[+]".foreground(.blue)), Message.changeVisibleColumnsCount(1)),
                    Text(model.sheet.visibleColumnsCount).foreground(color: .white).centered()
                        .width(3),
                    OnLeftClick(
                        Text("[-]".foreground(.blue)), Message.changeVisibleColumnsCount(-1)),
                ]),
        ])
    let buttons: [View<Message>] = [
        columnCountControls,
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
