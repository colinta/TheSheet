import Ashen
import Foundation

struct Model {
    typealias Status = (msg: String, timeout: TimeInterval)

    let sheet: Sheet
    let changeColumn: Int?
    let fileURL: URL?
    let status: Status?

    func replace(sheet: Sheet) -> Model {
        Model(sheet: sheet, changeColumn: changeColumn, fileURL: fileURL, status: status)
    }

    func replace(changeColumn: Int?) -> Model {
        Model(sheet: sheet, changeColumn: changeColumn, fileURL: fileURL, status: status)
    }

    func replace(status: Status?) -> Model {
        Model(sheet: sheet, changeColumn: changeColumn, fileURL: fileURL, status: status)
    }

    func replace(status: String) -> Model {
        Model(
            sheet: sheet, changeColumn: changeColumn, fileURL: fileURL,
            status: (msg: status, timeout: Date().timeIntervalSince1970 + STATUS_TIMEOUT))
    }
}

enum Message {
    case sheet(Sheet.Message)
    case changeColumn(Int)
    case replaceColumn(at: Int, with: Int)
    case reloadJSON
    case statusDidTimeout
    case saveJSON
    case quit
}

private let STATUS_TIMEOUT: TimeInterval = 3

func initial(sheet: Sheet, fileURL: URL?) -> () -> Initial<Model, Message> {
    return { Initial(Model(sheet: sheet, changeColumn: nil, fileURL: fileURL, status: nil)) }
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
    case let .sheet(message):
        return .model(model.replace(sheet: model.sheet.update(message)))
    case let .changeColumn(index):
        if model.changeColumn == index {
            return .model(model.replace(changeColumn: nil))
        }
        return .model(model.replace(changeColumn: index))
    case let .replaceColumn(oldIndex, columnIndex):
        guard columnIndex >= 0, columnIndex < model.sheet.columns.count else { return .noChange }

        return .model(model.replace(sheet: model.sheet.replace(selectedColumns: model.sheet.selectedColumns.enumerated().map { position, index in
                if position == oldIndex {
                    return columnIndex
                }
                else {
                    return index
                }
            })))
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
    // return .noChange
}

func render(model: Model, size: Size) -> [View<Message>] {
    _render(model, status: model.status.map { $0.0 })
}

private func _render(_ model: Model, status: String?) -> [View<Message>] {
    [
        OnKeyPress(key: .esc, { Message.quit }),
        OnKeyPress(key: .ctrl(.s), { Message.saveJSON }),
        OnKeyPress(key: .ctrl(.o), { Message.reloadJSON }),
        Flow(
            .down,
            [
                (.fixed, Text("The Sheet").height(1).centered().bold()),
                (
                    .flex1,
                    Columns(
                        model.sheet.selectedColumns.enumerated().compactMap { position, index in
                            guard index >= 0 && index < model.sheet.columns.count else { return nil }
                            let column = model.sheet.columns[index]
                            let columnView = column.render(model.sheet)
                            return ZStack(renderColumnEditor(model, position) + [
                                columnView.map { Message.sheet(Sheet.Message.column(index, $0)) }
                            ])
                    }
                    )
                ),
                (
                    .fixed,
                    MainButtons(status: status).height(1)
                ),
            ]),
    ]
}

func renderColumnEditor(_ model: Model, _ position: Int) -> [View<Message>] {
    guard model.sheet.columns.count > model.sheet.selectedColumns.count else { return [] }
    let current = model.sheet.selectedColumns[position]
    if model.changeColumn == position {
        return [
            OnLeftClick(Text("[x]").reversed(), Message.changeColumn(position)).compact().padding(right: 1).aligned(.topRight),
            Box(Stack(.down, model.sheet.columns.enumerated().map { newIndex, column in
                OnLeftClick(newIndex == current ? Text(column.title.bold()) : Text(column.title), Message.replaceColumn(at: position, with: newIndex))
            }).background(view: Text(" "))).aligned(.topRight)
        ]
    }
    else {
        return [OnLeftClick(Text("[…]"), Message.changeColumn(position)).compact().padding(right: 1).aligned(.topRight)]
    }
}

func MainButtons(status: String?) -> View<Message> {
    Flow(
        .ltr,
        [
            (.fixed, status.map { Text($0) } ?? Space()),
            (.flex1, Space()),
            (
                .fixed,
                OnLeftClick(
                    Text("Reload JSON").padding(left: 1, right: 1).centered()
                        .underlined(), Message.reloadJSON)
            ),
            (.fixed, Space().width(1)),
            (
                .fixed,
                OnLeftClick(
                    Text("Save").padding(left: 1, right: 1).centered().underlined(),
                    Message.saveJSON)
            ),
            (.fixed, Space().width(1)),
            (
                .fixed,
                OnLeftClick(
                    Text("Exit").padding(left: 1, right: 1).centered().underlined(),
                    Message.quit)
            ),
        ]
    )
}
