////
///  TakeRestView.swift
//

import Ashen

func TakeRestView<Msg>(
    _ onShort: @escaping @autoclosure () -> Msg, _ onLong: @escaping @autoclosure () -> Msg
) -> View<Msg> {
    Stack(
        .down,
        [
            Text("Take a Rest".bold()).centered().underlined(),
            Flow(
                .ltr,
                [
                    (.flex1, OnLeftClick(Text("Short").centered(), onShort())),
                    (.fixed, Text("|")),
                    (.flex1, OnLeftClick(Text("Long").centered(), onLong())),
                ]
            ).height(1),
        ])
}
