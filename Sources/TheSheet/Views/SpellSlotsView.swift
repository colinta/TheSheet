////
///  SpellSlotsView.swift
//

import Ashen

func SpellSlotsView(
    title: Attributed, spellSlots: [SpellSlot], sorceryPoints: Int,
    onToggle: @escaping ((slotIndex: Int, current: Int)) -> ControlMessage,
    onChangeMax: @escaping (Int, Int) -> ControlMessage,
    onBurn: @escaping (Int) -> ControlMessage, onBuy: @escaping (Int) -> ControlMessage
) -> View<ControlMessage> {
    let maxMax = spellSlots.reduce(0) { memo, slot in
        max(memo, slot.max, slot.current)
    }
    let titles: View<ControlMessage> = Stack(
        .down,
        spellSlots.map { slot in
            Text(slot.title).bold().padding(left: 1, right: 1).height(1)
        })
    let columns: [(FlowSize, View<ControlMessage>)] = (0..<maxMax).map { column in
        (
            .fixed,
            Stack(
                .down,
                spellSlots.enumerated().map { slotIndex, slot in
                    if max(slot.max, slot.current) > column {
                        return SlotCell(
                            isUsed: slot.current <= column,
                            { delta in
                                return onToggle(
                                    (slotIndex: slotIndex, current: slot.current + delta))
                            })
                    } else {
                        return Space().height(1)
                    }
                })
        )
    }
    let labels: View<ControlMessage> = Stack(
        .down,
        spellSlots.enumerated().map { slotIndex, slot in
            let burnPoints = SpellSlot.points(forLevel: slotIndex + 1)
            let buyPoints = SpellSlot.cost(ofLevel: slotIndex + 1)
            let canBurn = slot.current > 0
            let canBuy = slot.max > 0 && buyPoints.map { sorceryPoints >= $0 } ?? false
            let increaseMax =
                (Int(slot.title) ?? 0) < 9
                ? OnLeftClick(
                    Text("[+]".foreground(.green)), onChangeMax(slotIndex, slot.max + 1))
                : Text("[+]".foreground(.black))
            let decreaseMax =
                slot.max > 0
                ? OnLeftClick(Text("[-]".foreground(.red)), onChangeMax(slotIndex, slot.max - 1))
                : Text("[-]".foreground(.black))
            return Stack(
                .ltr,
                [
                    BuyCell(canBuy, buyPoints, onBuy(slotIndex)),
                    Space().width(1),
                    BurnCell(canBurn, burnPoints, onBurn(slotIndex)),
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
                        .flex1,
                        Flow(.rtl, [(.fixed, labels)] + [(.flex1, Space())] + columns.reversed())
                    ),
                ]),
        ])
}

func SlotCell(isUsed: Bool, _ onToggle: @escaping (Int) -> ControlMessage) -> View<ControlMessage> {
    OnLeftClick(
        Text("[\(isUsed ? "○" : "●")]".foreground(isUsed ? .none : .blue)),
        onToggle(isUsed ? 1 : -1))
}

func BurnCell(
    _ canBurn: Bool, _ burnPoints: Int, _ onBurn: @escaping @autoclosure SimpleEvent<ControlMessage>
) -> View<ControlMessage> {
    let burnText = "Burn(\(burnPoints))"
    return canBurn
        ? OnLeftClick(Text(burnText.foreground(.yellow)), onBurn())
        : Text(burnText.foreground(.black))
}
func BuyCell(
    _ canBuy: Bool, _ buyPoints: Int?, _ onBuy: @escaping @autoclosure SimpleEvent<ControlMessage>
) -> View<ControlMessage> {
    guard let buyPoints = buyPoints else { return Space().width(6) }
    let buyText = "Buy(\(buyPoints))"
    return canBuy
        ? OnLeftClick(Text(buyText.foreground(.blue)), onBuy())
        : Text(buyText.foreground(.black))

}
