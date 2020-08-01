////
///  SlotsView.swift
//

import Ashen

func SlotsView<Msg>(
    title: Attributed, slots: [Slot], _ onChange: @escaping ((index: Int, current: Int)) -> Msg
) -> View<Msg> {
    let maxMax = slots.reduce(0) { memo, slot in
        max(memo, slot.max)
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
                slots.enumerated().map { index, slot in
                    if slot.max > column {
                        return SlotCell(
                            isUsed: slot.current <= column,
                            { delta in
                                return onChange((index: index, current: slot.current + delta))
                            })
                    } else {
                        return Space()
                    }
                })
        )
    }
    let labels: View<Msg> = Stack(
        .down,
        slots.map { slot in
            Text("\(slot.current)/\(slot.max)").height(1)
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
        { onChange(isUsed ? 1 : -1) })
}
