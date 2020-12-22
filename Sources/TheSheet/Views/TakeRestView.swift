////
///  TakeRestView.swift
//

import Ashen

func TakeRestView(
    _ onRest: @escaping (Rest) -> SheetControl.Message
) -> View<SheetControl.Message> {
    Stack(
        .down,
        [
            Text("Take a Rest".bold()).centered().underlined(),
            Flow(
                .ltr,
                Rest.all.enumerated().flatMap { index, rest in
                    (index == 0
                    ? []
                    : [(FlowSize.fixed, Text("|"))])
                    + [(FlowSize.flex1, OnLeftClick(Text(rest.toString).centered(), onRest(rest)))]
                }
            ).height(1),
        ])
}
