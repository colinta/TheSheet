////
///  Roll.swift
//

enum Roll {
    case dice(Dice)
    case formula(Formula)

    var toReadable: String {
        switch self {
        case let .dice(dice):
            return dice.toReadableRoll
        case let .formula(formula):
            return formula.toReadableRoll
        }
    }
}
