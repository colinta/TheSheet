////
///  Slot.swift
//

struct Slot: Codable {
    let title: String
    let current: Int
    let max: Int
    let shouldResetOnLongRest: Bool

    func replace(current: Int) -> Slot {
        Slot(title: title, current: current, max: max, shouldResetOnLongRest: shouldResetOnLongRest)
    }

    func replace(max: Int) -> Slot {
        Slot(title: title, current: current, max: max, shouldResetOnLongRest: shouldResetOnLongRest)
    }

    func replace(shouldResetOnLongRest: Bool) -> Slot {
        Slot(title: title, current: current, max: max, shouldResetOnLongRest: shouldResetOnLongRest)
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
