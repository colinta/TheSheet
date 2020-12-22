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

        static func all(_ type: PointType?) -> [(Int, PointType)] {
            [
                (-5, .level),
                (-4, .hitPoints),
                (-3, .sorcery),
                (-2, .ki),
                (-1, .inspiration),
            ] + PointType.others(type)
        }

        var isBuiltIn: Bool {
            guard case .other = self else { return true }
            return false
        }

        var toVariable: Operation {
            .variable(toVariableName)
        }

        var toVariableName: String {
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

        var toMaxVariableName: String {
            "\(toVariableName).Max"
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
            return self.toVariableName == type.toVariableName
        }
    }

    let title: String
    let current: Int
    let max: Operation?
    let type: PointType?
    let readonly: Bool
    let shouldResetOn: Rest?

    var toVariable: Operation? {
        type.map { .variable($0.toVariableName) }
    }
    var toMaxVariable: Operation? {
        type.map { .variable($0.toMaxVariableName) }
    }

    var formulas: [Formula] {
        guard !readonly else { return [] }
        return type.map { type in
            [
                Formula(variable: type.toVariableName, operation: .integer(current)),
                (max.map { Formula(variable: type.toMaxVariableName, operation: $0) }),
            ].compactMap { $0 }
        } ?? []
    }

    static let `default` = Points(title: "", current: 0, max: nil, type: .hitPoints, readonly: false, shouldResetOn: nil)

    func replace(title: String) -> Points {
        Points(
            title: title, current: current, max: max, type: type,
            readonly: readonly, shouldResetOn: shouldResetOn)
    }

    func replace(current: Int) -> Points {
        Points(
            title: title, current: current, max: max, type: type,
            readonly: readonly, shouldResetOn: shouldResetOn)
    }

    func replace(max: Operation?) -> Points {
        Points(
            title: title, current: current, max: max, type: type,
            readonly: readonly, shouldResetOn: shouldResetOn)
    }

    func replace(type: PointType?) -> Points {
        Points(
            title: title, current: current, max: max, type: type,
            readonly: readonly, shouldResetOn: shouldResetOn)
    }

    func replace(readonly: Bool) -> Points {
        Points(
            title: title, current: current, max: max, type: type,
            readonly: readonly, shouldResetOn: shouldResetOn)
    }

    func replace(shouldResetOn: Rest?) -> Points {
        Points(
            title: title, current: current, max: max, type: type,
            readonly: readonly, shouldResetOn: shouldResetOn)
    }

    func `is`(_ type: Points.PointType) -> Bool {
        self.type?.is(type) ?? false
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
    private static func others(_ type: Points.PointType?) -> [(Int, Points.PointType)] {
        guard let type = type, case .other = type else { return [] }
        return [(0, type)]
    }
}
