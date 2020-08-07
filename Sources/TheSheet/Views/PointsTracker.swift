////
///  PointsTracker.swift
//

import Ashen

func PointsTracker<Msg>(points: Points, onChange: @escaping (Int, Int?) -> Msg) -> View<Msg> {
    Stack(
        .down,
        [
            Text(points.title.bold()).centered().underlined(),
            Flow(
                .ltr,
                PointsDisplay(points, onChange)
            ).bottomLined().height(1),
            PercentTitle("", points.current, points.max),
            Space().height(1),
        ])
}

private func PointsDisplay<Msg>(_ points: Points, _ onChange: @escaping (Int, Int?) -> Msg) -> [(
    FlowSize, View<Msg>
)] {
    if let pointsMax = points.max {
        return [
            (.flex1, PlusMinus(points.current, { onChange($0, pointsMax) }, .min(0))),
            (.fixed, Text(" / ")),
            (.flex1, PlusMinus(pointsMax, { onChange(points.current, $0) }, .min(0))),
        ]
    } else {
        return [
            (.flex1, PlusMinus(points.current, { onChange($0, points.max) }, .min(0)))
        ]
    }
}
