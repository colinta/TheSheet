////
///  Points.swift
//

struct Points: Codable {
    indirect enum PointType {
        case level
        case hitPoints
        case sorcery
        case ki
        case other(String, String)
        case many([PointType])

        var toVariables: [String] {
            switch self {
            case .level:
                return ["level"]
            case .hitPoints:
                return ["hitPoints"]
            case .sorcery:
                return ["sorceryPoints"]
            case .ki:
                return ["kiPoints"]
            case let .many(types):
                return types.flatMap(\.toVariables)
            case let .other(type, _):
                return [type]
            }
        }

        var toReadable: String {
            switch self {
            case .level:
                return "Level"
            case .hitPoints:
                return "Hit Points"
            case .sorcery:
                return "Sorcery Points"
            case .ki:
                return "Ki Points"
            case let .many(types):
                return types.map(\.toReadable).joined(separator: ", ")
            case let .other(_, title):
                return title
            }
        }

        func `is`(_ type: Points.PointType) -> Bool {
            if case let .many(types) = self {
                return types.contains(where: { $0.is(type) })
            }
            if case let .many(types) = type {
                return types.contains(where: { $0.is(self) })
            }
            return self.toReadable == type.toReadable
        }
    }

    let title: String
    let current: Int
    let max: Int?
    let type: PointType
    let shouldResetOnLongRest: Bool

    var formulas: [Formula] {
        type.toVariables.map { name in
            Formula(variable: name, operation: .integer(current))
        }
    }

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
        case variable
        case title
    }

    private static func from(string type: String) -> Points.PointType {
        switch type {
        case "level":
            return .level
        case "hitPoints":
            return .hitPoints
        case "sorcery":
            return .sorcery
        case "ki":
            return .ki
        default:
            return .other(type, type)
        }
    }

    private var toEncodeable: String {
        switch self {
        case .level:
            return "level"
        case .hitPoints:
            return "hitPoints"
        case .sorcery:
            return "sorcery"
        case .ki:
            return "ki"
        case .many:
            return "many"
        case .other:
            return "other"
        }
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let type = try values.decode(String.self, forKey: .type)
        switch type {
        case "other":
            let variable = try values.decode(String.self, forKey: .variable)
            let title = try values.decode(String.self, forKey: .title)
            self = .other(variable, title)
        case "many":
            let values = try values.decode([Points.PointType].self, forKey: .many)
            self = .many(values)
        default:
            self = Points.PointType.from(string: type)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(toEncodeable, forKey: .type)

        if case let .many(types) = self {
            try container.encode(types.map { $0.toEncodeable }, forKey: .many)
        } else if case let .other(variable, title) = self {
            try container.encode(variable, forKey: .variable)
            try container.encode(title, forKey: .title)
        }
    }
}
