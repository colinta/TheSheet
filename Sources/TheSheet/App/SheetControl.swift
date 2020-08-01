////
///  SheetControl.swift
//

import Ashen

enum SheetControl {
    enum Message {
        case updateSlots(index: Int, current: Int)
        case updateCount(current: Int, max: Int)
    }

    case slots(String, [Slot])
    case countable(title: String, current: Int, max: Int)
    case stats(String, [Stat])
    case attack(Attack)

    func update(_ message: Message) -> SheetControl {
        switch (self, message) {
        case let (.slots(title, slots), .updateSlots(updateIndex, current)):
            return .slots(
                title,
                slots.enumerated().map { index, slot in
                    guard index == updateIndex else { return slot }
                    return Slot(title: slot.title, current: current, max: slot.max)
                })
        case let (.countable(title, _, _), .updateCount(current, max)):
            return .countable(title: title, current: current, max: max)
        default:
            return self
        }
    }

    func render() -> View<Message> {
        switch self {
        case let .slots(title, slots):
            return SlotsView(
                title: title, slots: slots,
                { index, current in Message.updateSlots(index: index, current: current) })
        case let .countable(title, current, max):
            return Countable(
                title: title,
                current: current,
                max: max,
                onChange: { c, m in Message.updateCount(current: c, max: m) }
            )
        case let .attack(attack):
            return AttackView(attack)
        case let .stats(title, stats):
            return StatsView(title: title, stats: stats)
        }
    }

}
