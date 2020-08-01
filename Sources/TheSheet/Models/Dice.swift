////
///  Dice.swift
//

indirect enum Dice {
    case d(Int)
    case n(Int, Dice)
    case plus(Int)

    static let d4: Dice = .d(4)
    static let d6: Dice = .d(6)
    static let d8: Dice = .d(8)
    static let d10: Dice = .d(10)
    static let d12: Dice = .d(12)
    static let d20: Dice = .d(20)
    static let d100: Dice = .d(100)

    static func minus(_ delta: Int) -> Dice {
        .plus(-delta)
    }

    static func * (lhs: Int, rhs: Dice) -> Dice {
        .n(lhs, rhs)
    }

    var toReadableRoll: String {
        switch self {
        case let .d(d):
            return "1d\(d)"
        case let .n(n, d):
            return "\(n)\(d.toReadable)"
        case let .plus(i):
            return "\(i)"
        }
    }

    var toReadable: String {
        switch self {
        case let .d(d):
            return "d\(d)"
        case let .n(n, d):
            return "\(n)\(d.toReadable)"
        case let .plus(i):
            return "\(i)"
        }
    }
}
