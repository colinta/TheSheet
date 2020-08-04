////
///  SlotsView.swift
//

import Ashen

func SlotsView<Msg>(
    title: Attributed, slots: [Slot], sorceryPoints: Int, toggle onChange: @escaping ((level: Int, current: Int)) -> Msg, burn onBurn: @escaping (Int) -> Msg, buy onBuy: @escaping (Int) -> Msg
) -> View<Msg> {
    let maxMax = slots.reduce(0) { memo, slot in
        max(memo, slot.max, slot.current)
    }
    let titles: View<Msg> = Stack(
        .down,
        slots.map { slot in
            Text(slot.title).bold().padding(left: 1, right: 1).height(1)
        })
    let columns: [(FlowSize, View<Msg>)] = (0..<maxMax).map { column in
        (
            .fixed,
            Stack(
                .down,
                slots.enumerated().map { level, slot in
                    if max(slot.max, slot.current) > column {
                        return SlotCell(
                            isUsed: slot.current <= column,
                            { delta in
                                return onChange((level: level, current: slot.current + delta))
                            })
                    } else {
                        return Space()
                    }
                })
        )
    }
    let labels: View<Msg> = Stack(
        .down,
        slots.enumerated().map { level, slot in
            let canBurn = slot.current > 0
            let canBuy = Slot.cost(ofLevel: level).map { sorceryPoints >= $0} ?? false
            let burnText = "(\(Slot.points(forLevel: level)))🔥"
            let buyText = "💰(\(Slot.cost(ofLevel: level) ?? 0))"
            return Stack(.ltr, [
                canBurn ? OnLeftClick(Text(burnText), onBurn(level)) : Text(burnText.foreground(.black)),
                Space().width(1),
                canBuy ? OnLeftClick(Text(buyText), onBuy(level)) : Text(buyText.foreground(.black))
            ]).height(1)
        })
    return Stack(
        .down,
        [
            Text(title.bold()).centered().underlined(),
            Flow(
                .ltr,
                [
                    (.fixed, titles),
                    (
                        .fixed,
                        Flow(.rtl, [(.fixed, labels)] + [(.flex1, Space())] + columns.reversed())
                    ),
                ]),
        ])
}

func SlotCell<Msg>(isUsed: Bool, _ onChange: @escaping (Int) -> Msg) -> View<Msg> {
    OnLeftClick(
        Text("[\(isUsed ? "○" : "●")]".foreground(isUsed ? .none : .blue)),
        onChange(isUsed ? 1 : -1))
}
