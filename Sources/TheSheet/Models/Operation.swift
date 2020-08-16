////
///  Operation.swift
//

import Ashen

indirect enum Operation {
    case integer(Int)
    case bool(Bool)
    case string(String)

    case modifier(Operation)
    case variable(String)

    case add([Operation])
    case subtract([Operation])
    case multiply([Operation])
    case divide(Operation, Operation)
    case max([Operation])
    case min([Operation])
    case floor(Operation)
    case ceil(Operation)

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

    static func merge(_ formulas: [Formula], with others: [Formula]) -> [Formula] {
        formulas
            + others.filter { formula in
                !formulas.contains(where: { $0.is(named: formula.variable) })
            }
    }

    static func mergeAll(_ allFormulas: [[Formula]]) -> [Formula] {
        allFormulas.reduce([Formula]()) { memo, formulas in
            merge(memo, with: formulas)
        }
    }

    static func eval(_ sheet: Sheet, _ operation: Operation, _ dontRecur: [String] = [])
        -> Operation.Value
    {
        switch operation {
        case let .integer(i):
            return .integer(i)
        case let .bool(i):
            return .bool(i)
        case let .string(str):
            return .string(str)
        case let .modifier(operation):
            let result = eval(sheet, operation, dontRecur)
            switch result {
            case let .integer(i):
                return .modifier(i)
            default:
                return result
            }
        case let .variable(name):
            guard !dontRecur.contains(name),
                let operation = sheet.findOperation(variable: name)
            else {
                return .undefined
            }
            return eval(sheet, operation, dontRecur + [name])
        case let .add(operations):
            return Operation.reduce(sheet, operations, +)
        case let .subtract(operations):
            if operations.count == 1 {
                return Operation.reduce(sheet, [.integer(0), operations[0]], -)
            }
            return Operation.reduce(sheet, operations, -)
        case let .multiply(operations):
            return Operation.reduce(sheet, operations, *)
        case let .divide(lhs, rhs):
            return Operation.reduce(
                sheet, [lhs, rhs],
                { lhsInt, rhsInt in
                    guard rhsInt != 0 else { return 0 }
                    return lhsInt / rhsInt
                })

        case let .floor(operation):
            guard case let .divide(lhs, rhs) = operation else {
                return Operation.eval(sheet, operation)
            }
            let lhsValue = Operation.eval(sheet, lhs)
            let rhsValue = Operation.eval(sheet, rhs)
            guard
                let lhsInt: Int = lhsValue.toInt,
                let rhsInt: Int = rhsValue.toInt,
                rhsInt != 0
            else { return Operation.eval(sheet, operation) }
            return lhsValue.updateInt(Int((Float(lhsInt) / Float(rhsInt)).rounded(.down)))
        case let .ceil(operation):
            guard case let .divide(lhs, rhs) = operation else {
                return Operation.eval(sheet, operation)
            }
            let lhsValue = Operation.eval(sheet, lhs)
            let rhsValue = Operation.eval(sheet, rhs)
            guard
                let lhsInt: Int = lhsValue.toInt,
                let rhsInt: Int = rhsValue.toInt,
                rhsInt != 0
            else { return Operation.eval(sheet, operation) }
            return lhsValue.updateInt(Int((Float(lhsInt) / Float(rhsInt)).rounded(.up)))

        case let .max(operations):
            return Operation.reduce(sheet, operations, Swift.max)
        case let .min(operations):
            return Operation.reduce(sheet, operations, Swift.min)
        }
    }

    static func reduce(_ sheet: Sheet, _ operations: [Operation], _ fn: (Int, Int) -> Int) -> Value
    {
        var memo: Int?
        var isModifier: Bool?
        for operation in operations {
            switch Operation.eval(sheet, operation) {
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

    func toAttributed(_ sheet: Sheet) -> AttributedString {
        switch self {
        case let .integer(value):
            return value.description.foreground(.cyan)
        case let .bool(value):
            return value.description.foreground(.yellow)
        case let .string(value):
            return ("\"\(value)\"").foreground(.red)
        case let .modifier(operation):
            guard case let .integer(value) = operation else {
                return operation.toAttributed(sheet)
            }
            if value > 0 {
                return "+\(value.description)".foreground(.blue).bold()
            }
            else {
                return "-\(value.description)".foreground(.blue).bold()
            }
        case let .variable(name):
            guard sheet.findOperation(variable: name) != nil else {
                return name.underlined().foreground(.white).background(.red)
            }
            return name.underlined().foreground(.green)
        case let .add(operations):
            let insides = operations.map({ $0.toAttributed(sheet) }).reduce(AttributedString("")) {
                memo, attributed in
                if memo.isEmpty {
                    return attributed
                } else {
                    return memo + AttributedString(" ") + attributed
                }
            }
            return "(".foreground(.magenta) + "+ ".foreground(.white) + insides
                + ")".foreground(.magenta)
        case let .subtract(operations):
            let insides = operations.map({ $0.toAttributed(sheet) }).reduce(AttributedString("")) {
                memo, attributed in
                if memo.isEmpty {
                    return attributed
                } else {
                    return memo + AttributedString(" ") + attributed
                }
            }
            return "(".foreground(.magenta) + "- ".foreground(.white) + insides
                + ")".foreground(.magenta)
        case let .multiply(operations):
            let insides = operations.map({ $0.toAttributed(sheet) }).reduce(AttributedString("")) {
                memo, attributed in
                if memo.isEmpty {
                    return attributed
                } else {
                    return memo + AttributedString(" ") + attributed
                }
            }
            return "(".foreground(.magenta) + "× ".foreground(.white) + insides
                + ")".foreground(.magenta)
        case let .divide(lhs, rhs):
            return "(".foreground(.magenta) + "÷ ".foreground(.white) + lhs.toAttributed(sheet)
                + " " + rhs.toAttributed(sheet) + ")".foreground(.magenta)
        case let .floor(operation):
            return "(".foreground(.magenta) + "floor ".foreground(.white)
                + operation.toAttributed(sheet) + ")".foreground(.magenta)
        case let .ceil(operation):
            return "(".foreground(.magenta) + "ceil ".foreground(.white)
                + operation.toAttributed(sheet) + ")".foreground(.magenta)
        case let .max(operations):
            let insides = operations.map({ $0.toAttributed(sheet) }).reduce(AttributedString("")) {
                memo, attributed in
                if memo.isEmpty {
                    return attributed
                } else {
                    return memo + AttributedString(" ") + attributed
                }
            }
            return "(".foreground(.magenta) + "max ".foreground(.white) + insides
                + ")".foreground(.magenta)
        case let .min(operations):
            let insides = operations.map({ $0.toAttributed(sheet) }).reduce(AttributedString("")) {
                memo, attributed in
                if memo.isEmpty {
                    return attributed
                } else {
                    return memo + AttributedString(" ") + attributed
                }
            }
            return "(".foreground(.magenta) + "min ".foreground(.white) + insides
                + ")".foreground(.magenta)
        }
    }

    var toEditable: String {
        switch self {
        case let .integer(value):
            return value.description
        case let .bool(value):
            return value.description
        case let .string(value):
            return value
        case let .modifier(operation):
            return operation.toEditable
        case let .variable(name):
            return name
        case let .add(operations):
            return "(+ \(operations.map(\.toEditable).joined(separator: " ")))"
        case let .subtract(operations):
            return "(- \(operations.map(\.toEditable).joined(separator: " ")))"
        case let .multiply(operations):
            return "(× \(operations.map(\.toEditable).joined(separator: " ")))"
        case let .divide(lhs, rhs):
            return "(÷ \(lhs.toEditable) \(rhs.toEditable))"
        case let .floor(operation):
            return "(floor \(operation.toEditable))"
        case let .ceil(operation):
            return "(ceil \(operation.toEditable))"
        case let .max(operations):
            return "(max \(operations.map(\.toEditable).joined(separator: " ")))"
        case let .min(operations):
            return "(min \(operations.map(\.toEditable).joined(separator: " ")))"
        }
    }
}

extension Operation: Codable {
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
            let modifier = try values.decode(Operation.self, forKey: .value)
            self = .modifier(modifier)
        case "variable":
            let variable = try values.decode(String.self, forKey: .value)
            self = .variable(variable)
        case "add":
            let operations = try values.decode([Operation].self, forKey: .value)
            self = .add(operations)
        case "subtract":
            let operations = try values.decode([Operation].self, forKey: .value)
            self = .subtract(operations)
        case "multiply":
            let operations = try values.decode([Operation].self, forKey: .value)
            self = .multiply(operations)
        case "divide":
            let lhs = try values.decode(Operation.self, forKey: .lhs)
            let rhs = try values.decode(Operation.self, forKey: .rhs)
            self = .divide(lhs, rhs)
        case "floor":
            let operation = try values.decode(Operation.self, forKey: .value)
            self = .floor(operation)
        case "ceil":
            let operation = try values.decode(Operation.self, forKey: .value)
            self = .ceil(operation)
        case "max":
            let operations = try values.decode([Operation].self, forKey: .value)
            self = .max(operations)
        case "min":
            let operations = try values.decode([Operation].self, forKey: .value)
            self = .min(operations)
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
        case let .add(operations):
            try container.encode("add", forKey: .type)
            try container.encode(operations, forKey: .value)
        case let .subtract(operations):
            try container.encode("subtract", forKey: .type)
            try container.encode(operations, forKey: .value)
        case let .multiply(operations):
            try container.encode("multiply", forKey: .type)
            try container.encode(operations, forKey: .value)
        case let .divide(lhs, rhs):
            try container.encode("divide", forKey: .type)
            try container.encode(lhs, forKey: .lhs)
            try container.encode(rhs, forKey: .rhs)
        case let .floor(operation):
            try container.encode("floor", forKey: .type)
            try container.encode(operation, forKey: .value)
        case let .ceil(operation):
            try container.encode("ceil", forKey: .type)
            try container.encode(operation, forKey: .value)
        case let .max(operations):
            try container.encode("max", forKey: .type)
            try container.encode(operations, forKey: .value)
        case let .min(operations):
            try container.encode("min", forKey: .type)
            try container.encode(operations, forKey: .value)
        }
    }
}
