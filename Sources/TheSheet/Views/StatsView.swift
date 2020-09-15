////
///  StatsView.swift
//

import Ashen

func StatsView<Msg>(title: String, stats: [Stat], sheet: Sheet, onRoll: @escaping (Roll) -> Msg)
    -> View<Msg>
{
    Stack(
        .down,
        [
            Text(title).bold().centered().underlined(),
            BasedOnSize { size in
                let statWidth = 6
                if size.width > stats.count * statWidth {
                    return Flow(
                        .ltr,
                        [(.fixed, Space().width(1))]
                            + stats.flatMap { stat in
                                [
                                    (.flex1, StatView(stat, sheet: sheet, onRoll: onRoll)),
                                    (.fixed, Space().width(1)),
                                ]
                            })
                }
                else {
                    let rows = Int((Float(stats.count) / Float(size.width / statWidth)).rounded(.up))
                    let perRow = stats.count / rows
                    let views: [View<Msg>] = (0..<rows).map { row in
                        let statViews = stats[(row * perRow)..<min(stats.count, (row + 1) * perRow)]
                        return Flow(
                            .ltr,
                            [(.fixed, Space().width(1))]
                                + statViews.flatMap { stat in
                                    [
                                        (.flex1, StatView(stat, sheet: sheet, onRoll: onRoll)),
                                        (.fixed, Space().width(1)),
                                    ]
                                })
                    }
                    return Stack(.down, views)
                }
            }
        ])
}

func StatView<Msg>(_ stat: Stat, sheet: Sheet, onRoll: @escaping (Roll) -> Msg) -> View<Msg> {
    StatView(title: stat.title, value: stat.value, sheet: sheet, onRoll: onRoll)
}

func StatView<Msg>(title: String, value op: Operation, sheet: Sheet, onRoll: @escaping (Roll) -> Msg) -> View<Msg> {
    let value = op.eval(sheet)
    let valueText: View<Msg> = Text(value.toAttributed).centered().underlined()
    let valueView: View<Msg>
    if let roll = value.toRollable {
        valueView = OnLeftClick(valueText, onRoll(roll))
    } else {
        valueView = valueText
    }
    return Stack(
        .down,
        [
            valueView,
            Text(title).centered(),
        ])
}
