////
///  PointsTracker.swift
//

import Ashen

func PointsTracker<Msg>(points: Points, onChange: @escaping (Int, Int?) -> Msg) -> View<Msg> {
    Stack(
        .down,
        [
            Text(points.title.bold()).centered().underlined(),
            PointsDisplay(points, onChange).bottomLined().height(1),
            PercentTitle("", points.current, points.max),
            Space().height(1),
        ])
}

private func PointsDisplay<Msg>(_ points: Points, _ onChange: @escaping (Int, Int?) -> Msg) -> View<
    Msg
> {
    if let pointsMax = points.max {
        return Flow(
            .ltr,
            [
                (.flex1, Space()),
                (.fixed, PlusMinus(points.current, { onChange($0, pointsMax) })),
                (.fixed, Text(" / \(pointsMax)")),
                (.flex1, Space()),
            ])
    } else {
        return PlusMinus(points.current, { onChange($0, points.max) }).centered()
    }
}
