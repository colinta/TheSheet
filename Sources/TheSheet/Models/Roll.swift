////
///  Roll.swift
//

enum Roll {
    case dice(Dice)
    case formula(Formula)

    func toReadable(_ sheet: Sheet) -> String {
        switch self {
        case let .dice(dice):
            return dice.toReadableRoll
        case let .formula(formula):
            return sheet.eval(formula).toReadable
        }
    }
}

extension Roll: Codable {
    enum Error: Swift.Error {
        case decoding
    }

    enum CodingKeys: String, CodingKey {
        case type
        case value
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let type = try values.decode(String.self, forKey: .type)
        switch type {
        case "dice":
            let dice = try values.decode(Dice.self, forKey: .value)
            self = .dice(dice)
        case "formula":
            let formula = try values.decode(Formula.self, forKey: .value)
            self = .formula(formula)
        default:
            throw Error.decoding
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .dice(dice):
            try container.encode("dice", forKey: .type)
            try container.encode(dice, forKey: .value)
        case let .formula(formula):
            try container.encode("formula", forKey: .type)
            try container.encode(formula, forKey: .value)
        }
    }
}
