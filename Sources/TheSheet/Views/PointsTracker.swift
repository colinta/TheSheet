////
///  PointsTracker.swift
//

import Ashen

func PointsTracker<Msg>(points: Points, onChange: @escaping (Int, Int) -> Msg) -> View<Msg> {
    Stack(
        .down,
        [
            Text(points.title.bold()).centered().underlined(),
            Flow(
                .ltr,
                [
                    (.flex1, PlusMinus(points.current, { onChange($0, points.max) }, .min(0))),
                    (.fixed, Text(" / ")),
                    (.flex1, PlusMinus(points.max, { onChange(points.current, $0) }, .min(0))),
                ]
            ).bottomLined().height(1),
            PercentTitle("", points.current, points.max),
            Space().height(1),
        ])
}
