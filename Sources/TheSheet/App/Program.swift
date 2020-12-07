////
///  Program.swift
//

import Ashen
import Foundation

enum Message {
    case sheetMessage(Sheet.Message)
    case controlEditingMessage(EditableControl.Message)

    case changeColumn(Int)
    case editColumn(Int)
    case startAddControl(Int)
    case addControl(SheetControl, to: Int)
    case relocateControl(from: IndexPath, to: Int)
    case saveControl

    case changeVisibleColumn(Int)
    case changeVisibleColumnsCount(Int)
    case replaceColumn(at: Int, with: Int)

    case scrollColumns(Int)
    case setColumnScrollSize(Int, LocalViewport)

    case scrollModal(Int)
    case setModalScrollSize(LocalViewport)
    case cancelModal

    case addDie(Roll, Dice)
    case removeDie(Roll, Dice)
    case setRollModifier(Roll, Int)
    case roll(Roll)

    case statusDidTimeout
    case undo
    case reloadJSON
    case saveJSON
    case quit
}

func initial(sheet: Sheet, fileURL: URL?, status: String? = nil) -> () -> Initial<Model, Message> {
    // let command: Command<Message> = HttpRequest.get(url: "https://www.dnd5eapi.co/api/spells/acid-arrow/")
    //     .decodeJson(Dnd5eSpell.self)
    //     .start(onComplete: Message.httpResult)
    var model = Model(sheet: sheet, fileURL: fileURL)
    if let status = status {
        model = model.replace(status: status)
    }
    return {
        Initial(
            model,
            commands: []
        )
    }
}

func update(model: inout Model, message: Message) -> State<Model, Message> {
    switch message {
    case let .sheetMessage(.columnMessage(_, .controlMessage(_, .delegate(.roll(roll))))):
        return .model(model.roll(roll))
    case let .sheetMessage(.columnMessage(columnIndex, .controlMessage(controlIndex, .delegate(.command(command))))):
        return .update(model, [command.map { Message.sheetMessage(.columnMessage(columnIndex, .controlMessage(controlIndex, $0)))}])
    case let .sheetMessage(.columnMessage(columnIndex, .delegate(delegate))):
        switch delegate {
        case .editColumn:
            return .model(model.replace(editColumn: columnIndex))

        case let .showControlEditor(controlIndex):
            let control = model.sheet.columns[columnIndex].controls[controlIndex]
            guard let editor = control.editor else {
                return .model(model.stopEditing())
            }
            return .model(
                model.replace(editControl: controlIndex, inColumn: columnIndex, editor: editor))
        case let .relocateControl(controlIndex):
            return .model(model.replace(relocateControl: controlIndex, inColumn: columnIndex))
        case .stopEditing:
            return .model(model.stopEditing())
        }
    case let .sheetMessage(message):
        return .model(model.replace(sheet: model.sheet.update(message)))
    case let .controlEditingMessage(message):
        guard case let .editControl(column, control, editor) = model.editing else {
            return .model(model.stopEditing())
        }
        let newEditor = editor.update(message)
        return .model(model.replace(editControl: control, inColumn: column, editor: newEditor))

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
    case let .addControl(control, columnIndex):
        guard columnIndex >= 0, columnIndex < model.sheet.columns.count else { return .noChange }
        return .model(model.addControl(control, toColumn: columnIndex).stopEditing())
    case .saveControl:
        guard case let .editControl(column, control, editor) = model.editing else {
            return .model(model.stopEditing())
        }
        return .model(
            model.replace(control: control, inColumn: column, with: editor.control).stopEditing())
    case let .relocateControl(from, toColumn):
        let oldColumn = model.sheet.columns[from[0]]
        let control = oldColumn.controls[from[1]]
        let newColumn = model.sheet.columns[toColumn]
        return .model(
            model.replace(
                sheet:
                    model.sheet.replace(
                        column: oldColumn.replace(
                            controls: oldColumn.controls.removing(at: from[1])),
                        at: from[0]
                    )
                    .replace(
                        column: newColumn.replace(controls: [control] + newColumn.controls),
                        at: toColumn)
            ).stopEditing())

    case let .changeVisibleColumn(delta):
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
    case let .replaceColumn(oldIndex, newIndex):
        guard
            oldIndex >= 0, oldIndex < model.sheet.columns.count,
            newIndex >= 0, newIndex < model.sheet.columns.count
        else { return .noChange }

        return .model(
            model.replace(
                sheet: model.sheet.replace(
                    columns: model.sheet.columns.enumerated().map {
                        index, column in
                        if index == oldIndex {
                            return model.sheet.columns[newIndex]
                        } else if index == newIndex {
                            return model.sheet.columns[oldIndex]
                        } else {
                            return column
                        }
                    })
            )
            .stopEditing()
        )

    case let .scrollColumns(delta):
        let scrollOffset = max(
            0, min(model.columnScrollOffset + delta, model.columnScrollMaxOffset))
        return .model(model.replace(columnScrollOffset: scrollOffset))
    case let .setColumnScrollSize(index, scrollViewport):
        return .model(model.replace(column: index, scrollViewport: scrollViewport))

    case let .setModalScrollSize(scrollViewport):
        return .model(model.replace(modalScrollViewport: scrollViewport))
    case let .scrollModal(delta):
        let scrollOffset = max(0, min(model.modalScrollOffset + delta, model.modalScrollMaxOffset))
        return .model(model.replace(modalScrollOffset: scrollOffset))
    case .cancelModal:
        return .model(model.stopEditing().stopRolling())

    case let .addDie(roll, die):
        return .model(model.replace(editRolling: roll.adding(die)))
    case let .removeDie(roll, die):
        return .model(model.replace(editRolling: roll.removing(die)))
    case let .setRollModifier(roll, value):
        return .model(model.replace(editRolling: roll.replace(modifier: value)))
    case let .roll(roll):
        return .model(model.roll(roll))

    case .statusDidTimeout:
        let now = Date().timeIntervalSince1970
        if let timeout = model.status?.timeout, timeout > now {
            return .update(
                model,
                [Timeout(timeout - now + 0.01, Message.statusDidTimeout)])
        }

        return .model(model.replace(status: nil))
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
            return showStatus(model: model.stopEditing(), status: "JSON Saved")
        } catch {
            return showStatus(model: model.stopEditing(), status: "Error saving JSON")
        }
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

private func showStatus(model: Model, status: String?) -> State<Model, Message> {
    if let status = status {
        return .update(
            model.replace(status: status),
            [Timeout(STATUS_TIMEOUT, Message.statusDidTimeout)])
    } else {
        return .model(model.replace(status: nil))
    }
}

func render(model: Model) -> [View<Message>] {
    let status = model.status.map { $0.0 }
    var views: [View<Message>] = [
        OnKeyPress(.up, Message.scrollColumns(-1)),
        OnKeyPress(.down, Message.scrollColumns(1)),
        OnKeyPress(.left, Message.changeVisibleColumn(-1)),
        OnKeyPress(.right, Message.changeVisibleColumn(1)),
        OnKeyPress(.pageUp, Message.scrollColumns(-25)),
        OnKeyPress(.pageDown, Message.scrollColumns(25)),
        OnKeyPress(.space, Message.scrollColumns(25)),
        OnKeyPress(.ctrl(.s), Message.saveJSON),
        OnKeyPress(.ctrl(.r), Message.reloadJSON),
        OnKeyPress(.ctrl(.x), Message.quit),
        OnKeyPress(.esc, Message.quit),
        OnKeyPress(.ctrl(.z), Message.undo),
        Flow(
            .down,
            [
                (.fixed, Text("The Sheet").height(1).centered().bold()),
                (
                    .flex1,
                    Columns(
                        (model.firstVisibleColumn..<model.firstVisibleColumn
                            + model.sheet.visibleColumnsCount).map { ($0, model.sheet.columns[$0]) }
                            .map { index, column in
                                renderColumn(
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
    ]

    if !(model.isAddingToColumn() || model.isEditingControl()) {
        views.append(OnMouseWheel(Space(), Message.scrollColumns))
    }

    if let info = model.editingControl {
        views.append(
            renderControlEditor(
                model: model, column: info.column, control: info.control, editor: info.editor))
    }

    if let info = model.addingToColumn {
        views.append(renderControlSelector(model: model, addToColumn: info))
    }

    if let info = model.relocatingControl {
        views.append(
            renderControlRelocator(
                model: model, relocatingControl: info.control, inColumn: info.column))
    }

    if let info = model.rolling {
        views.append(renderRoller(model: model, roll: info))
    }

    return views
}

private func inModal(
    model: Model, view: View<Message>, header: View<Message>? = nil, footer: View<Message>? = nil
) -> View<Message> {
    ZStack([
        IgnoreMouse(),
        IgnoreKeys(),
        OnKeyPress(.ctrl(.c), Message.quit),
        OnKeyPress(.esc, Message.cancelModal),
        OnLeftClick(
            Space().modifyCharacters { pt, size, c in
                return AttributedCharacter(
                    character: AttributedCharacter.null.character, attributes: []
                ).styled(.foreground(.black)).styled(.background(.none))
            }, Message.cancelModal, .highlight(false)),
        Stack(
            .down,
            [
                header,
                Scroll(
                    view,
                    onResizeContent: { scrollViewport in
                        Message.setModalScrollSize(scrollViewport)
                    },
                    .offset(y: model.modalScrollOffset)
                ).border(
                    .single
                ),
                footer,
            ].compactMap { $0 }
        )
        .background(view: Text(" "))
        .minWidth(75, fittingContainer: true)
        .fitInContainer(dimension: .height)
        .aligned(.middleCenter),
        OnMouseWheel(Space(), Message.scrollModal),
    ])
}

private func renderControlSelector(model: Model, addToColumn: Int) -> View<Message> {
    inModal(
        model: model,
        view: Stack(
            .down,
            SheetControl.all.map({ title, control in
                OnLeftClick(
                    Text("[+]".foreground(.green) + " \(title)"),
                    Message.addControl(control, to: addToColumn))
            })
        ))
}

private func renderControlEditor(
    model: Model, column columnIndex: Int, control controlIndex: Int, editor: EditableControl
) -> View<Message> {
    inModal(
        model: model,
        view: editor.render(model.sheet).map { Message.controlEditingMessage($0) },
        footer: Flow(
            .ltr,
            [
                (.flex1, Space()),
                (.fixed, OnLeftClick(Text(" Cancel ").border(.single), Message.cancelModal)),
                (.fixed, Space().width(1)),
                (
                    .fixed,
                    editor.canSave
                        ? OnLeftClick(Text(" Save ").border(.single), Message.saveControl)
                        : Text(" Save ".foreground(.black)).border(.single)
                ),
            ])
    )
}

private func renderControlRelocator(
    model: Model, relocatingControl controlIndex: Int, inColumn columnIndex: Int
) -> View<Message> {
    inModal(
        model: model,
        view: Stack(
            .down,
            model.sheet.columns.enumerated().map { index, column in
                return index == columnIndex
                    ? Text(column.title.bold())
                    : OnLeftClick(
                        Text(column.title),
                        Message.relocateControl(from: [columnIndex, controlIndex], to: index))
            }.map { $0.centered() }
        ).aligned(.middleCenter)
    )
}

private func renderRoller(
    model: Model, roll: Roll
) -> View<Message> {
    let addButtons: View<Message> = Stack(
        .ltr,
        [
            OnLeftClick(Text("d4\n[+]").border(.single).foreground(color: .green), .addDie(roll, .d4)),
            OnLeftClick(Text("d6\n[+]").border(.single).foreground(color: .green), .addDie(roll, .d6)),
            OnLeftClick(Text("d8\n[+]").border(.single).foreground(color: .green), .addDie(roll, .d8)),
            OnLeftClick(Text("d10\n[+]").border(.single).foreground(color: .green), .addDie(roll, .d10)),
            OnLeftClick(Text("d12\n[+]").border(.single).foreground(color: .green), .addDie(roll, .d12)),
            OnLeftClick(Text("d20\n[+]").border(.single).foreground(color: .green), .addDie(roll, .d20)),
        ])
    let removeButtons: View<Message> = Stack(
        .ltr,
        roll.dice.flatMap { die in
            return (0..<die.n).map { _ -> View<Message> in
                OnLeftClick(
                    Text("d\(die.d)\n[-]").border(.single).foreground(color: .blue),
                    .removeDie(roll, Dice(n: 1, d: die.d)))
            }
        })
    let result: AttributedString
    if let (rolls, total) = model.rollResult {
        let rollsStr = rolls.map { d, v in "d\(d): \(v)" }.joined(separator: ", ")
        result =
            AttributedString("Rolls: \(rollsStr), Total: ")
            + AttributedString("\(total)", attributes: [.bold])
    } else {
        result = AttributedString("")
    }
    return inModal(
        model: model,
        view: Stack(
            .down,
            [
                addButtons.minHeight(3), removeButtons.minHeight(3),
                Stack(
                    .ltr,
                    [
                        Text("Modifier: "),
                        PlusMinus(
                            roll.modifier, { Message.setRollModifier(roll, $0) }),
                    ]),
                Text(result),
                Flow(
                    .ltr,
                    [
                        (.flex1, Space()),
                        (.fixed, OnLeftClick(Text("Roll").border(.single), Message.roll(roll))),
                    ]),
            ])
    )
}

private func renderColumn(_ model: Model, _ column: SheetColumn, columnIndex: Int) -> View<Message> {
    let columnView = column.render(
        model.sheet,
        isEditing: model.isEditingColumn(columnIndex),
        editingControl: model.editingControl.flatMap({ $0.column == columnIndex ? $0.control : nil }
        )
    )
    return ZStack(
        [
            Scroll(
                columnView.map {
                    Message.sheetMessage(Sheet.Message.columnMessage(columnIndex, $0))
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

private func renderColumnEditor(_ model: Model, _ columnIndex: Int) -> [View<Message>] {
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
            editButton,
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
                            newIndex == columnIndex
                                ? Text(column.title.bold()) : Text(column.title),
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

private func MainButtons(model: Model, status: String?) -> View<Message> {
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
            Text("Undo (" + "Z".underlined() + ")")
                .foreground(color: model.canUndo ? .none : .black)
                .padding(left: 1, right: 1)
                .border(.single), Message.undo, .isEnabled(model.canUndo)),
        OnLeftClick(
            Text("R".underlined() + "eload")
                .padding(left: 1, right: 1)
                .border(.single), Message.reloadJSON),
        OnLeftClick(
            Text("S".underlined() + "ave")
                .padding(left: 1, right: 1)
                .border(.single),
            Message.saveJSON),
        OnLeftClick(
            Text("Save & E" + "x".underlined() + "it")
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
