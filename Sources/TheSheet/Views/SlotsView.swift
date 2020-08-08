////
///  SlotsView.swift
//

import Ashen

func SlotsView<Msg>(
    title: Attributed, slots: [Slot], sorceryPoints: Int,
    onToggle: @escaping ((level: Int, current: Int)) -> Msg,
    onChangeMax: @escaping (Int, Int) -> Msg,
    onBurn: @escaping (Int) -> Msg, onBuy: @escaping (Int) -> Msg
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
                                return onToggle((level: level, current: slot.current + delta))
                            })
                    } else {
                        return Space().height(1)
                    }
                })
        )
    }
    let labels: View<Msg> = Stack(
        .down,
        slots.enumerated().map { level, slot in
            let burnPoints = Slot.points(forLevel: level)
            let buyPoints = Slot.cost(ofLevel: level)
            let canBurn = slot.current > 0
            let canBuy = buyPoints.map { sorceryPoints >= $0 } ?? false
            let increaseMax = OnLeftClick(
                Text("[+]".foreground(.green)), onChangeMax(level, slot.max + 1))
            let decreaseMax =
                slot.max > 0
                ? OnLeftClick(Text("[-]".foreground(.red)), onChangeMax(level, slot.max - 1))
                : Text("[-]".foreground(.black))
            return Stack(
                .ltr,
                [
                    BuyCell(canBuy, buyPoints, onBuy(level)),
                    Space().width(1),
                    BurnCell(canBurn, burnPoints, onBurn(level)),
                    Space().width(1),
                    decreaseMax, increaseMax,
                ]
            ).height(1)
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

func SlotCell<Msg>(isUsed: Bool, _ onToggle: @escaping (Int) -> Msg) -> View<Msg> {
    OnLeftClick(
        Text("[\(isUsed ? "○" : "●")]".foreground(isUsed ? .none : .blue)),
        onToggle(isUsed ? 1 : -1))
}

func BurnCell<Msg>(
    _ canBurn: Bool, _ burnPoints: Int, _ onBurn: @escaping @autoclosure SimpleEvent<Msg>
) -> View<Msg> {
    let burnText = "Burn(\(burnPoints))"
    return canBurn
        ? OnLeftClick(Text(burnText.foreground(.yellow)), onBurn())
        : Text(burnText.foreground(.black))
}
func BuyCell<Msg>(
    _ canBuy: Bool, _ buyPoints: Int?, _ onBuy: @escaping @autoclosure SimpleEvent<Msg>
) -> View<Msg> {
    guard let buyPoints = buyPoints else { return Space() }
    let buyText = "Buy(\(buyPoints))"
    return canBuy
        ? OnLeftClick(Text(buyText.foreground(.blue)), onBuy())
        : Text(buyText.foreground(.black))

}
