////
///  PointsTracker.swift
//

import Ashen

func PointsTracker(points: Points, sheet: Sheet, onChange: @escaping (Int) -> ControlMessage) -> View<ControlMessage> {
    Stack(
        .down,
        [
            Text(points.title.bold()).centered().underlined(),
            points.readonly
            ? ReadonlyPointsDisplay(points, sheet, onChange).bottomLined().height(1)
            : PointsDisplay(points, sheet, onChange).bottomLined().height(1),
            PointsPercentTitle(points, sheet),
            Space().height(1),
        ])
}

private func PointsDisplay(_ points: Points, _ sheet: Sheet, _ onChange: @escaping (Int) -> ControlMessage) -> View<ControlMessage> {
    if let pointsMax = points.max?.eval(sheet).toInt {
        return Flow(
            .ltr,
            [
                (.flex1, Space()),
                (.fixed, PlusMinus(points.current, { onChange($0) })),
                (.fixed, Text(" / \(pointsMax)")),
                (.flex1, Space()),
            ])
    } else {
        return PlusMinus(points.current, { onChange($0) }).centered()
    }
}

private func ReadonlyPointsDisplay(_ points: Points, _ sheet: Sheet, _ onChange: @escaping (Int) -> ControlMessage) -> View<ControlMessage> {
    let current = points.toVariable?.eval(sheet).toReadable ?? ""
    if let pointsMax = points.max?.eval(sheet) {
        return Flow(
            .ltr,
            [
                (.flex1, Space()),
                (.fixed, Text(current).aligned(.topRight)),
                (.fixed, Text(" / ")),
                (.fixed, Text(pointsMax.toReadable)),
                (.flex1, Space()),
            ])
    } else {
        return Text(current).centered()
    }
}

private func PointsPercentTitle(_ points: Points, _ sheet: Sheet) -> View<ControlMessage> {
    if points.readonly, let current = points.toVariable?.eval(sheet).toInt {
        let pointsMax = points.toMaxVariable?.eval(sheet).toInt
        return PercentTitle(current, pointsMax)
    } else {
        return PercentTitle(points.current, points.max?.eval(sheet).toInt)
    }
}
