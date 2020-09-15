////
///  Points.swift
//

struct Points: Codable {
    indirect enum PointType {
        case level
        case hitPoints
        case sorcery
        case ki
        case inspiration
        case other(String, String)

        // the tuple is (sort, PointType), hence the negative numbers
        static func all(_ types: [PointType]) -> [(Int, PointType)] {
            [
                (-5, .level),
                (-4, .hitPoints),
                (-3, .sorcery),
                (-2, .ki),
                (-1, .inspiration),
            ] + PointType.others(types)
        }

        var isBuiltIn: Bool {
            guard case .other = self else { return true }
            return false
        }

        var toVariable: String {
            switch self {
            case .level:
                return "level"
            case .hitPoints:
                return "hitPoints"
            case .sorcery:
                return "sorceryPoints"
            case .ki:
                return "kiPoints"
            case .inspiration:
                return "inspiration"
            case let .other(type, _):
                return type
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
            case .inspiration:
                return "Inspiration"
            case let .other(_, title):
                return title
            }
        }

        func `is`(_ type: PointType) -> Bool {
            return self.toVariable == type.toVariable
        }
    }

    let title: String
    let current: Int
    let max: Int?
    let types: [PointType]
    let shouldResetOnLongRest: Bool

    var formulas: [Formula] {
        types.map(\.toVariable).flatMap { name in
            [
                Formula(variable: name, operation: .integer(current)),
                (max.map { Formula(variable: "\(name).Max", operation: .integer($0)) }),
            ].compactMap { $0 }
        }
    }

    static let `default` = Points(title: "", current: 0, max: nil, types: [], shouldResetOnLongRest: false)

    func replace(title: String) -> Points {
        Points(
            title: title, current: current, max: max, types: types,
            shouldResetOnLongRest: shouldResetOnLongRest)
    }

    func replace(current: Int) -> Points {
        Points(
            title: title, current: current, max: max, types: types,
            shouldResetOnLongRest: shouldResetOnLongRest)
    }

    func replace(max: Int?) -> Points {
        Points(
            title: title, current: current, max: max, types: types,
            shouldResetOnLongRest: shouldResetOnLongRest)
    }

    func replace(types: [PointType]) -> Points {
        Points(
            title: title, current: current, max: max, types: types,
            shouldResetOnLongRest: shouldResetOnLongRest)
    }

    func replace(shouldResetOnLongRest: Bool) -> Points {
        Points(
            title: title, current: current, max: max, types: types,
            shouldResetOnLongRest: shouldResetOnLongRest)
    }

    func `is`(_ type: Points.PointType) -> Bool {
        types.contains(where: { $0.is(type) })
    }
}

extension Points.PointType: Codable {
    enum CodingKeys: String, CodingKey {
        case type
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
        case "inspiration":
            return .inspiration
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
        case .inspiration:
            return "inspiration"
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
        default:
            self = Points.PointType.from(string: type)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(toEncodeable, forKey: .type)
        if case let .other(variable, title) = self {
            try container.encode(variable, forKey: .variable)
            try container.encode(title, forKey: .title)
        }
    }
}

extension Points.PointType {
    private static func others(_ types: [Points.PointType]) -> [(Int, Points.PointType)] {
        types.enumerated().reduce([(Int, Points.PointType)]()) { memo, index_type in
            let (_, type) = index_type
            guard case .other = type else { return memo }
            return memo + [index_type]
        }
    }
}
