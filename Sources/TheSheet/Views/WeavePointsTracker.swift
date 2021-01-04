////
///  PointsTracker.swift
//

import Ashen

func WeavePointsTracker(points: WeavePoints, sheet: Sheet, onChange: @escaping (Int, Int) -> ControlMessage) -> View<ControlMessage> {
    Stack(
        .down,
        [
            Text(points.title.bold()).centered().underlined(),
            PercentTitle(points.current.eval(sheet).toInt ?? 0, points.max.eval(sheet).toInt),
            Flow(.ltr, [(.flex1, Text("Available:")), (.fixed, Text(points.current.eval(sheet).toAttributed)), (.fixed, Space().width(7))]),
            Flow(.ltr, [(.flex1, Text("Used Ki:")), (.fixed, PlusMinus(points.kiUsed, { onChange($0, points.sorceryUsed) }, .min(0)))]),
            Flow(.ltr, [(.flex1, Text("Used Sorcery:")), (.fixed, PlusMinus(points.sorceryUsed, { onChange(points.kiUsed, $0) }, .min(0)))]),
            Space().height(1),
        ])
}
