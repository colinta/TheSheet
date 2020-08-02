////
///  Countable.swift
//

import Ashen

func Countable<Msg>(
    title: Attributed, current: Int, max: Int, onChange: @escaping (Int, Int) -> Msg
)
    -> View<Msg>
{
    Stack(
        .down,
        [
            Flow(
                .ltr,
                [
                    (.flex1, PlusMinus(current, { onChange($0, max) }, .min(0))),
                    (.fixed, Text(" / ")),
                    (.flex1, PlusMinus(max, { onChange(current, $0) }, .min(0))),
                ]
            ).bottomLined().height(1),
            PercentTitle(title.bold(), current, max),
        ])
}
