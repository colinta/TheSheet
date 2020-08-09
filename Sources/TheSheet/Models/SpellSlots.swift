////
///  SpellSlots.swift
//

import Ashen

struct SpellSlots: Codable {
    let title: String
    let slots: [SpellSlot]
    let shouldResetOnLongRest: Bool

    func replace(title: String) -> SpellSlots {
        SpellSlots(title: title, slots: slots, shouldResetOnLongRest: shouldResetOnLongRest)
    }

    func replace(slots: [SpellSlot]) -> SpellSlots {
        let lastWithSlot = slots.enumerated().reduce(nil as Int?) { memo, index_slot in
            let (index, slot) = index_slot
            if slot.max > 0 {
                return index
            }
            return memo
        }

        let filteredSlots: [SpellSlot]
        if let lastWithSlot = lastWithSlot {
            filteredSlots = Array(slots[0...lastWithSlot])
        } else {
            filteredSlots = [SpellSlot(title: "1", current: 0, max: 0)]
        }
        return SpellSlots(
            title: title, slots: filteredSlots, shouldResetOnLongRest: shouldResetOnLongRest)
    }
}

struct SpellSlot: Codable {
    let title: String
    let current: Int
    let max: Int

    func replace(current: Int) -> SpellSlot {
        SpellSlot(title: title, current: current, max: max)
    }

    func replace(max: Int) -> SpellSlot {
        SpellSlot(title: title, current: current, max: max)
    }

    static func points(forLevel level: Int) -> Int {
        return level
    }

    static func cost(ofLevel level: Int) -> Int? {
        switch level {
        case 1:
            return 2
        case 2:
            return 3
        case 3:
            return 5
        case 4:
            return 6
        case 5:
            return 7
        default:
            return nil
        }
    }
}
