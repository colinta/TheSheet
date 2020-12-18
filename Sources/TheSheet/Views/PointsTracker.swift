////
///  PointsTracker.swift
//

import Ashen

func PointsTracker<Msg>(points: Points, sheet: Sheet, onChange: @escaping (Int, Int?) -> Msg) -> View<Msg> {
    Stack(
        .down,
        [
            Text(points.title.bold()).centered().underlined(),
            points.readonly
            ? ReadonlyPointsDisplay(points, sheet: sheet, onChange).bottomLined().height(1)
            : PointsDisplay(points, onChange).bottomLined().height(1),
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

private func ReadonlyPointsDisplay<Msg>(_ points: Points, sheet: Sheet, _ onChange: @escaping (Int, Int?) -> Msg) -> View<
    Msg
> {
    let current = points.toVariable?.eval(sheet).toReadable ?? ""
    if let pointsMax = points.max {
        return Flow(
            .ltr,
            [
                (.flex1, Space()),
                (.fixed, Text(current).aligned(.topRight)),
                (.fixed, Text(" / \(pointsMax)")),
                (.flex1, Space()),
            ])
    } else {
        return Text(current).centered()
    }
}
