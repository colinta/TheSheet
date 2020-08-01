////
///  FourUp.swift
//

import Ashen

func FourUp<Msg>(_ stat1: Stat, _ stat2: Stat, _ stat3: Stat, _ stat4: Stat) -> View<Msg> {
    Flow(
        .ltr,
        [
            (.fixed, Space().width(1)),
            (.flex1, StatView(stat1)),
            (.fixed, Space().width(1)),
            (.flex1, StatView(stat2)),
            (.fixed, Space().width(1)),
            (.flex1, StatView(stat3)),
            (.fixed, Space().width(1)),
            (.flex1, StatView(stat4)),
            (.fixed, Space().width(1)),
        ])
}
