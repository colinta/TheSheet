////
///  StatsView.swift
//

import Ashen

func StatsView<Msg>(title: String, stats: [Stat]) -> View<Msg> {
    Stack(
        .down,
        [
            Text(title).bold().centered().underlined(),
            Flow(
                .ltr,
                [(.fixed, Space().width(1))]
                    + stats.flatMap { stat in
                        [(.flex1, StatView(stat)), (.fixed, Space().width(1))]
                    }),
        ])
}
