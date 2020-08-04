////
///  Dice.swift
//

indirect enum Dice {
    case d(Int)
    case n(Int, Dice)

    static let d4: Dice = .d(4)
    static let d6: Dice = .d(6)
    static let d8: Dice = .d(8)
    static let d10: Dice = .d(10)
    static let d12: Dice = .d(12)
    static let d20: Dice = .d(20)
    static let d100: Dice = .d(100)

    static func * (lhs: Int, rhs: Dice) -> Dice {
        .n(lhs, rhs)
    }

    var toReadableRoll: String {
        switch self {
        case let .d(d):
            return "1d\(d)"
        case let .n(n, d):
            return "\(n)\(d.toReadable)"
        }
    }

    var toReadable: String {
        switch self {
        case let .d(d):
            return "d\(d)"
        case let .n(n, d):
            return "\(n)\(d.toReadable)"
        }
    }
}

extension Dice: Codable {
    enum CodingKeys: String, CodingKey {
        case dice
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let dice = try values.decode(String.self, forKey: .dice)
        self = Dice.decode(dice)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(toReadable, forKey: .dice)
    }

    private static func decode(_ dice: String) -> Dice {
        if dice.hasPrefix("d") {
            var faces = dice
            faces.removeFirst()
            let d = Int(faces) ?? 1
            return .d(d)
        } else if dice.contains("d") {
            let parts = dice.split(separator: "d", maxSplits: 2)
            let n = Int(parts[0]) ?? 1
            let d = decode(String(parts[1]))
            return .n(n, d)
        } else {
            return .d(1)
        }
    }
}
