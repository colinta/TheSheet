////
///  Formula.swift
//

indirect enum Formula {
    typealias Lookup = [String: Formula]

    enum Value {
        case modifier(Int)
        case integer(Int)
        case bool(Bool)
        case string(String)
        case undefined

        var toReadable: String {
            switch self {
            case let .modifier(value):
                return value.toModString
            case let .integer(value):
                return value.description
            case let .bool(value):
                return value.description
            case let .string(str):
                return str
            case .undefined:
                return "???"
            }
        }

        static func + (lhs: Value, rhs: Value) -> Value {
            if case let .integer(lhsValue) = lhs, case let .integer(rhsValue) = rhs {
                return .integer(lhsValue + rhsValue)
            }
            if case let .bool(lhsValue) = lhs, case let .bool(rhsValue) = rhs {
                return .bool(lhsValue && rhsValue)
            }
            if case let .integer(lhsValue) = lhs, case let .modifier(rhsValue) = rhs {
                return .integer(lhsValue + rhsValue)
            }
            if case let .modifier(lhsValue) = lhs, case let .modifier(rhsValue) = rhs {
                return .modifier(lhsValue + rhsValue)
            }
            if case let .modifier(lhsValue) = lhs, case let .integer(rhsValue) = rhs {
                return .modifier(lhsValue + rhsValue)
            }
            if case let .string(lhsValue) = lhs, case let .string(rhsValue) = rhs {
                return .string(lhsValue + rhsValue)
            }
            return .string(lhs.toReadable + "+" + rhs.toReadable)
        }
    }

    case integer(Int)
    case bool(Bool)
    case string(String)

    case modifier(Formula)
    case variable(String)

    case add([Formula])
    case max([Formula])
    case min([Formula])

    static func merge(_ formulas: Lookup, with others: Lookup) -> Lookup {
        formulas.merging(others) { $1 }
    }

    static func mergeAll(_ formulas: [Lookup]) -> Lookup {
        formulas.reduce(Lookup()) { memo, formula in
            memo.merging(formula) { $1 }
        }
    }

    static func reduce(_ formulas: [Formula], _ sheet: Sheet, _ fn: (Int, Int) -> Int) -> Value {
        var memo: Int?
        var isModifier: Bool?
        for formula in formulas {
            switch sheet.eval(formula) {
            case let .integer(value):
                isModifier = isModifier ?? false
                if let prev = memo {
                    memo = fn(prev, value)
                } else {
                    memo = value
                }
            case let .modifier(value):
                isModifier = isModifier ?? true
                if let prev = memo {
                    memo = fn(prev, value)
                } else {
                    memo = value
                }
            default:
                return .undefined
            }
        }
        if let isModifier = isModifier, let memo = memo {
            return isModifier ? .modifier(memo) : .integer(memo)
        }
        return .undefined
    }

    var toEditable: String {
        switch self {
        case let .integer(value):
            return value.description
        case let .bool(value):
            return value.description
        case let .string(value):
            return value
        case let .modifier(formula):
            return formula.toEditable
        case let .variable(name):
            return name
        case let .add(formulas):
            return "(+ \(formulas.map(\.toEditable).joined(separator: " ")))"
        case let .max(formulas):
            return "(max \(formulas.map(\.toEditable).joined(separator: " ")))"
        case let .min(formulas):
            return "(min \(formulas.map(\.toEditable).joined(separator: " ")))"
        }
    }
}

extension Formula: Codable {
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
        case "integer":
            let integer = try values.decode(Int.self, forKey: .value)
            self = .integer(integer)
        case "bool":
            let bool = try values.decode(Bool.self, forKey: .value)
            self = .bool(bool)
        case "string":
            let string = try values.decode(String.self, forKey: .value)
            self = .string(string)
        case "modifier":
            let modifier = try values.decode(Formula.self, forKey: .value)
            self = .modifier(modifier)
        case "variable":
            let variable = try values.decode(String.self, forKey: .value)
            self = .variable(variable)
        case "add":
            let formulas = try values.decode([Formula].self, forKey: .value)
            self = .add(formulas)
        case "max":
            let formulas = try values.decode([Formula].self, forKey: .value)
            self = .max(formulas)
        case "min":
            let formulas = try values.decode([Formula].self, forKey: .value)
            self = .min(formulas)
        default:
            throw Error.decoding
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .integer(integer):
            try container.encode("integer", forKey: .type)
            try container.encode(integer, forKey: .value)
        case let .bool(bool):
            try container.encode("bool", forKey: .type)
            try container.encode(bool, forKey: .value)
        case let .string(string):
            try container.encode("string", forKey: .type)
            try container.encode(string, forKey: .value)
        case let .modifier(modifier):
            try container.encode("modifier", forKey: .type)
            try container.encode(modifier, forKey: .value)
        case let .variable(variable):
            try container.encode("variable", forKey: .type)
            try container.encode(variable, forKey: .value)
        case let .add(formulas):
            try container.encode("add", forKey: .type)
            try container.encode(formulas, forKey: .value)
        case let .max(formulas):
            try container.encode("max", forKey: .type)
            try container.encode(formulas, forKey: .value)
        case let .min(formulas):
            try container.encode("min", forKey: .type)
            try container.encode(formulas, forKey: .value)
        }
    }
}
