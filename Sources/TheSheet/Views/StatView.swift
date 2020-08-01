////
///  StatView.swift
//

import Ashen

func StatView<Msg>(_ stat: Stat) -> View<Msg> {
    Stack(
        .down,
        [
            Text(stat.value.toReadable).centered().underlined(),
            Text(stat.title).centered(),
        ])
}
