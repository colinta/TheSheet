////
///  Formula.swift
//

indirect enum Formula {
    typealias Lookup = [String: Formula]

    case integer(Int)
    case bool(Bool)
    case string(String)

    case modifier(Formula)
    case variable(String)

    case add([Formula])
    case subtract([Formula])
    case multiply([Formula])
    case divide(Formula, Formula)
    case max([Formula])
    case min([Formula])
    case floor(Formula)
    case ceil(Formula)

    enum Value {
        case modifier(Int)
        case integer(Int)
        case bool(Bool)
        case string(String)
        case undefined

        var toInt: Int? {
            switch self {
            case let .modifier(value):
                return value
            case let .integer(value):
                return value
            default:
                return nil
            }
        }

        func updateInt(_ value: Int) -> Value {
            switch self {
            case .modifier:
                return .modifier(value)
            default:
                return .integer(value)
            }
        }

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
            if let lhsValue = lhs.toInt, let rhsValue = rhs.toInt {
                return lhs.updateInt(lhsValue + rhsValue)
            }
            if case let .bool(lhsValue) = lhs, case let .bool(rhsValue) = rhs {
                return .bool(lhsValue && rhsValue)
            }
            if case let .string(lhsValue) = lhs, case let .string(rhsValue) = rhs {
                return .string(lhsValue + rhsValue)
            }
            return .string(lhs.toReadable + "+" + rhs.toReadable)
        }
    }

    static func merge(_ formulas: Lookup, with others: Lookup) -> Lookup {
        formulas.merging(others) { $1 }
    }

    static func mergeAll(_ formulas: [Lookup]) -> Lookup {
        formulas.reduce(Lookup()) { memo, formula in
            memo.merging(formula) { $1 }
        }
    }

    static func eval(_ sheet: Sheet, _ formula: Formula, _ dontRecur: [String] = []) -> Formula.Value {
        switch formula {
        case let .integer(i):
            return .integer(i)
        case let .bool(i):
            return .bool(i)
        case let .string(str):
            return .string(str)
        case let .modifier(formula):
            let result = eval(sheet, formula, dontRecur)
            switch result {
            case let .integer(i):
                return .modifier(i)
            default:
                return result
            }
        case let .variable(name):
            guard !dontRecur.contains(name),
                let formula = sheet.formulas[name]
            else {
                return .undefined
            }
            return eval(sheet, formula, dontRecur + [name])
        case let .add(formulas):
            return Formula.reduce(sheet, formulas, +)
        case let .subtract(formulas):
            return Formula.reduce(sheet, formulas, -)
        case let .multiply(formulas):
            return Formula.reduce(sheet, formulas, *)
        case let .divide(lhs, rhs):
            return Formula.reduce(sheet, [lhs, rhs], { lhsInt, rhsInt in
                guard rhsInt != 0 else { return 0 }
                return lhsInt / rhsInt
            })

        case let .floor(formula):
            guard case let .divide(lhs, rhs) = formula else { return Formula.eval(sheet, formula) }
            let lhsValue = Formula.eval(sheet, lhs)
            let rhsValue = Formula.eval(sheet, rhs)
            guard
                let lhsInt: Int = lhsValue.toInt,
                let rhsInt: Int = rhsValue.toInt,
                rhsInt != 0
            else { return Formula.eval(sheet, formula) }
            return lhsValue.updateInt(Int((Float(lhsInt) / Float(rhsInt)).rounded(.down)))
        case let .ceil(formula):
            guard case let .divide(lhs, rhs) = formula else { return Formula.eval(sheet, formula) }
            let lhsValue = Formula.eval(sheet, lhs)
            let rhsValue = Formula.eval(sheet, rhs)
            guard
                let lhsInt: Int = lhsValue.toInt,
                let rhsInt: Int = rhsValue.toInt,
                rhsInt != 0
            else { return Formula.eval(sheet, formula) }
            return lhsValue.updateInt(Int((Float(lhsInt) / Float(rhsInt)).rounded(.up)))

        case let .max(formulas):
            return Formula.reduce(sheet, formulas, Swift.max)
        case let .min(formulas):
            return Formula.reduce(sheet, formulas, Swift.min)
        }
    }

    static func reduce(_ sheet: Sheet, _ formulas: [Formula], _ fn: (Int, Int) -> Int) -> Value {
        var memo: Int?
        var isModifier: Bool?
        for formula in formulas {
            switch Formula.eval(sheet, formula) {
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
        case let .subtract(formulas):
            return "(- \(formulas.map(\.toEditable).joined(separator: " ")))"
        case let .multiply(formulas):
            return "(× \(formulas.map(\.toEditable).joined(separator: " ")))"
        case let .divide(lhs, rhs):
            return "(÷ \(lhs.toEditable) \(rhs.toEditable))"
        case let .floor(formula):
            return "(floor \(formula.toEditable))"
        case let .ceil(formula):
            return "(ceil \(formula.toEditable))"
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
        case lhs
        case rhs
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
        case "subtract":
            let formulas = try values.decode([Formula].self, forKey: .value)
            self = .subtract(formulas)
        case "multiply":
            let formulas = try values.decode([Formula].self, forKey: .value)
            self = .multiply(formulas)
        case "divide":
            let lhs = try values.decode(Formula.self, forKey: .lhs)
            let rhs = try values.decode(Formula.self, forKey: .rhs)
            self = .divide(lhs, rhs)
        case "floor":
            let formula = try values.decode(Formula.self, forKey: .value)
            self = .floor(formula)
        case "ceil":
            let formula = try values.decode(Formula.self, forKey: .value)
            self = .ceil(formula)
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
        case let .subtract(formulas):
            try container.encode("subtract", forKey: .type)
            try container.encode(formulas, forKey: .value)
        case let .multiply(formulas):
            try container.encode("multiply", forKey: .type)
            try container.encode(formulas, forKey: .value)
        case let .divide(lhs, rhs):
            try container.encode("divide", forKey: .type)
            try container.encode(lhs, forKey: .lhs)
            try container.encode(rhs, forKey: .rhs)
        case let .floor(formula):
            try container.encode("floor", forKey: .type)
            try container.encode(formula, forKey: .value)
        case let .ceil(formula):
            try container.encode("ceil", forKey: .type)
            try container.encode(formula, forKey: .value)
        case let .max(formulas):
            try container.encode("max", forKey: .type)
            try container.encode(formulas, forKey: .value)
        case let .min(formulas):
            try container.encode("min", forKey: .type)
            try container.encode(formulas, forKey: .value)
        }
    }
}
