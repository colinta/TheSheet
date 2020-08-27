////
///  StatsView.swift
//

import Ashen

func StatsView<Msg>(title: String, stats: [Stat], sheet: Sheet) -> View<Msg> {
    Stack(
        .down,
        [
            Text(title).bold().centered().underlined(),
            Flow(
                .ltr,
                [(.fixed, Space().width(1))]
                    + stats.flatMap { stat in
                        [(.flex1, StatView(stat, sheet: sheet)), (.fixed, Space().width(1))]
                    }),
            Space().height(1),
        ])
}

func StatView<Msg>(_ stat: Stat, sheet: Sheet) -> View<Msg> {
    Stack(
        .down,
        [
            Text(stat.value.eval(sheet).toAttributed).centered().underlined(),
            Text(stat.title).centered(),
        ])
}
