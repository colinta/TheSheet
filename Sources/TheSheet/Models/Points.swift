////
///  Points.swift
//

struct Points: Codable {
    indirect enum PointType {
        case hitPoints
        case sorcery
        case ki
        case other(String)
        case many([PointType])

        var toReadable: String {
            switch self {
            case .hitPoints:
                return "Hit Points"
            case .sorcery:
                return "Sorcery Points"
            case .ki:
                return "Ki Points"
            case let .many(types):
                return types.map(\.toReadable).joined(separator: ", ")
            case let .other(type):
                return type
            }
        }


        func `is`(_ type: Points.PointType) -> Bool {
            switch (self, type) {
            case (.hitPoints, .hitPoints):
                return true
            case (.sorcery, .sorcery):
                return true
            case (.ki, .ki):
                return true
            default:
                guard case let .many(types) = self else { return false }
                return types.contains(where: { $0.is(type) })
            }
        }
    }

    let title: String
    let current: Int
    let max: Int?
    let type: PointType
    let shouldResetOnLongRest: Bool

    func replace(current: Int) -> Points {
        Points(
            title: title, current: current, max: max, type: type,
            shouldResetOnLongRest: shouldResetOnLongRest)
    }

    func replace(max: Int?) -> Points {
        Points(
            title: title, current: current, max: max, type: type,
            shouldResetOnLongRest: shouldResetOnLongRest)
    }

    func `is`(_ type: Points.PointType) -> Bool {
        self.type.is(type)
    }
}

extension Points.PointType: Codable {
    enum CodingKeys: String, CodingKey {
        case type
        case many
    }

    private static func from(string type: String) -> Points.PointType {
        switch type {
        case "hitPoints":
            return .hitPoints
        case "sorcery":
            return .sorcery
        case "ki":
            return .ki
        default:
            return .other(type)
        }
    }

    private var toEncodeable: String {
        switch self {
        case .hitPoints:
            return "hitPoints"
        case .sorcery:
            return "sorcery"
        case .ki:
            return "ki"
        case .many:
            return "many"
        case let .other(type):
            return type
        }
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let type = try values.decode(String.self, forKey: .type)
        switch type {
        case "many":
            let values = try values.decode([String].self, forKey: .many)
            self = .many(values.map { Points.PointType.from(string: $0) })
        default:
            self = Points.PointType.from(string: type)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(toEncodeable, forKey: .type)

        if case let .many(types) = self {
            try container.encode(types.map { $0.toEncodeable }, forKey: .many)
        }
    }
}
