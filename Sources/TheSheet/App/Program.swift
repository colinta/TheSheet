import Ashen

struct Model {
    var columns: [SheetColumn]
    var formulas: [String: Formula]
}

enum Message {
    case column(Int, SheetColumn.Message)
    case reload
    case save
    case quit
}

func initial(_ model: Model) -> () -> Initial<Model, Message> {
    return { Initial(model) }
}

func update(model: inout Model, message: Message) -> State<Model, Message> {
    switch message {
    case let .column(changeIndex, message):
        model.columns = model.columns.enumerated().map { index, column in
            guard index == changeIndex else { return column }
            return column.update(message)
        }
        return .model(model)
    case .reload:
        return .noChange
    case .save:
        return .noChange
    case .quit:
        return .quit
    }
    // return .noChange
}

func render(model: Model, size: Size) -> View<Message> {
    Flow(
        .down,
        [
            (.fixed, OnKeyPress(key: .esc, { Message.quit })),
            (.fixed, Text("The Sheet").height(1).centered().bold()),
            (
                .flex1,
                Columns(
                    model.columns.enumerated().map { index, column in
                        column.render().map { Message.column(index, $0) }
                    })
            ),
            (
                .fixed,
                Flow(
                    .ltr,
                    [
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
                ).height(1)
            ),
        ])
}
