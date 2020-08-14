////
///  Roll.swift
//

enum Roll {
    case dice(Dice)
    case operation(Operation)

    func toReadable(_ sheet: Sheet) -> String {
        switch self {
        case let .dice(dice):
            return dice.toReadableRoll
        case let .operation(operation):
            return Operation.eval(sheet, operation).toReadable
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
        case "operation":
            let operation = try values.decode(Operation.self, forKey: .value)
            self = .operation(operation)
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
        case let .operation(operation):
            try container.encode("operation", forKey: .type)
            try container.encode(operation, forKey: .value)
        }
    }
}
