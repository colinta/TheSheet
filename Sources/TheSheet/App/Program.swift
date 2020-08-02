import Ashen
import Foundation

struct Model {
    let current: Sheet
    let original: Sheet
    let status: (msg: String, timeout: TimeInterval)?
}

enum Message {
    case column(Int, SheetColumn.Message)
    case reload
    case didTimeout
    case save
    case quit
}

private let STATUS_TIMEOUT: TimeInterval = 3

func initial(_ sheet: Sheet) -> () -> Initial<Model, Message> {
    return { Initial(Model(current: sheet, original: sheet, status: nil)) }
}

func update(model: inout Model, message: Message) -> State<Model, Message> {
    var (current, original) = (model.current, model.original)
    switch message {
    case let .column(changeIndex, message):
        current.columns = current.columns.enumerated().map { index, column in
            guard index == changeIndex else { return column }
            return column.update(message)
        }
        return .model(Model(current: current, original: original, status: model.status))
    case .reload:
        return .update(
            Model(
                current: original, original: original,
                status: (
                    msg: "JSON Reloaded", timeout: Date().timeIntervalSince1970 + STATUS_TIMEOUT
                )), [Timeout(STATUS_TIMEOUT, Message.didTimeout)])
    case .save:
        return .update(
            Model(
                current: current, original: current,
                status: (msg: "JSON Saved", timeout: Date().timeIntervalSince1970 + STATUS_TIMEOUT)),
            [Timeout(STATUS_TIMEOUT, Message.didTimeout)])
    case .didTimeout:
        guard let status = model.status else { return .noChange }
        let now = Date().timeIntervalSince1970
        if let timeout = model.status?.timeout, timeout > now {
            return .update(
                Model(current: current, original: original, status: status),
                [Timeout(timeout - now + 0.01, Message.didTimeout)])
        }
        return .model(Model(current: current, original: original, status: nil))
    case .quit:
        return .quit
    }
    // return .noChange
}

func render(model: Model, size: Size) -> [View<Message>] {
    _render(model.current, status: model.status.map { $0.0 })
}

private func _render(_ sheet: Sheet, status: String?) -> [View<Message>] {
    [
        OnKeyPress(key: .esc, { Message.quit }),
        Flow(
            .down,
            [
                (.fixed, Text("The Sheet").height(1).centered().bold()),
                (
                    .flex1,
                    Columns(
                        sheet.columns.enumerated().compactMap { index, column in
                            if sheet.selectedColumns.contains(index) {
                                return column.render().map { Message.column(index, $0) }
                            } else {
                                return nil
                            }
                        })
                ),
                (
                    .fixed,
                    MainButtons(status: status).height(1)
                ),
            ]),
    ]
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
                        .underlined(), { Message.reload })
            ),
            (.fixed, Space().width(1)),
            (
                .fixed,
                OnLeftClick(
                    Text("Save").padding(left: 1, right: 1).centered().underlined(),
                    { Message.save })
            ),
            (.fixed, Space().width(1)),
            (
                .fixed,
                OnLeftClick(
                    Text("Exit").padding(left: 1, right: 1).centered().underlined(),
                    { Message.quit })
            ),
        ]
    )
}
