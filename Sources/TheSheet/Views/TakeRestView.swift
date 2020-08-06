////
///  TakeRestView.swift
//

import Ashen

func TakeRestView<Msg>(
    _ onShort: @escaping @autoclosure SimpleEvent<Msg>,
    _ onLong: @escaping @autoclosure SimpleEvent<Msg>
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
