////
///  Operation.swift
//

import Ashen

indirect enum Operation {
    struct Dice: Codable {
        let n: Int
        let d: Int

        var toReadable: String {
            "\(n)d\(d)"
        }
    }

    case integer(Int)
    case dice(Dice)
    case bool(Bool)
    case string(String)

    case modifier(Int)
    case variable(String)

    case add([Operation])
    case multiply([Operation])
    case divide(Operation, Operation)
    case max([Operation])
    case min([Operation])
    case floor(Operation)
    case round(Operation)
    case ceil(Operation)

    case `if`(Operation, Operation, Operation)
    case equal(Operation, Operation)
    case greaterThan(Operation, Operation)
    case greaterThanEqual(Operation, Operation)
    case lessThan(Operation, Operation)
    case lessThanEqual(Operation, Operation)

    enum Value {
        case integer(Int)
        case modifier(Int)
        case diceAdd([Dice], Int)
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

        var toBool: Bool? {
            switch self {
            case let .integer(value):
                return value == 0
            case let .bool(value):
                return value
            case let .modifier(value):
                return value == 0
            default:
                return nil
            }
        }

        var toString: String? {
            switch self {
            case let .string(value):
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
            case let .integer(value):
                return value.description
            case let .modifier(value):
                return value.toModString
            case let .diceAdd(dice, add):
                let diceStr = dice.map({ $0.toReadable }).joined(separator: "+")
                if add == 0 {
                    return diceStr
                }
                return "\(diceStr)+\(add)"
            case let .bool(value):
                return value.description
            case let .string(str):
                return str
            case .undefined:
                return "???"
            }
        }

        var toAttributed: AttributedString {
            switch self {
            case .integer:
                return toReadable.foreground(.cyan)
            case .modifier:
                return toReadable.foreground(.blue)
            case .diceAdd:
                return toReadable.foreground(.brightBlue)
            case .bool:
                return toReadable.foreground(.yellow)
            case .string:
                return toReadable.foreground(.red)
            case .undefined:
                return "???".foreground(.white).background(.red)
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

    enum Error: Swift.Error {
        case decoding
        case div0
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
        case let .integer(value):
            return .integer(value)
        case let .bool(value):
            return .bool(value)
        case let .dice(dice):
            return .diceAdd([dice], 0)
        case let .string(value):
            return .string(value)
        case let .modifier(value):
            return .modifier(value)
        case let .variable(name):
            guard !dontRecur.contains(name),
                let operation = sheet.findOperation(variable: name)
            else {
                return .undefined
            }
            return eval(sheet, operation, dontRecur + [name])
        case let .add(operations):
            var dice = [Dice]()
            var sum = 0
            var isModifier: Bool?
            for operation in operations {
                let resolved = eval(sheet, operation, dontRecur)
                if case let .diceAdd(moreDice, value) = resolved {
                    dice += moreDice
                    sum += value
                } else if case let .integer(value) = resolved {
                    isModifier = isModifier ?? false
                    sum += value
                } else if case let .modifier(value) = resolved {
                    isModifier = isModifier ?? true
                    sum += value
                } else {
                    return .undefined
                }
            }

            if dice.isEmpty {
                return isModifier == true ? .modifier(sum) : .integer(sum)
            }
            return .diceAdd(dice, sum)
        case let .multiply(operations):
            return reduce(toValues(operations, sheet, dontRecur), *)
        case let .divide(lhs, rhs):
            return reduce(
                toValues([lhs, rhs], sheet, dontRecur),
                { lhsInt, rhsInt in
                    guard rhsInt != 0 else { return 0 }
                    return lhsInt / rhsInt
                })

        case let .floor(operation):
            guard case let .divide(lhs, rhs) = operation else {
                return eval(sheet, operation)
            }
            return reduce(
                toValues([lhs, rhs], sheet, dontRecur),
                { lhsInt, rhsInt in
                    guard rhsInt != 0 else { throw Error.div0 }
                    return Int((Float(lhsInt) / Float(rhsInt)).rounded(.down))
                })
        case let .round(operation):
            guard case let .divide(lhs, rhs) = operation else {
                return eval(sheet, operation)
            }
            return reduce(
                toValues([lhs, rhs], sheet, dontRecur),
                { lhsInt, rhsInt in
                    guard rhsInt != 0 else { throw Error.div0 }
                    return Int((Float(lhsInt) / Float(rhsInt)).rounded())
                })
        case let .ceil(operation):
            guard case let .divide(lhs, rhs) = operation else {
                return eval(sheet, operation)
            }
            return reduce(
                toValues([lhs, rhs], sheet, dontRecur),
                { lhsInt, rhsInt in
                    guard rhsInt != 0 else { throw Error.div0 }
                    return Int((Float(lhsInt) / Float(rhsInt)).rounded(.up))
                })

        case let .max(operations):
            return reduce(toValues(operations, sheet, dontRecur), Swift.max)
        case let .min(operations):
            return reduce(toValues(operations, sheet, dontRecur), Swift.min)

        case let .if(condition, lhs, rhs):
            guard let pass = eval(sheet, condition).toBool else { return .undefined }
            return pass ? eval(sheet, lhs) : eval(sheet, rhs)
        case let .equal(lhs, rhs):
            return test(lhs, rhs, sheet, dontRecur, ==, ==)
        case let .greaterThan(lhs, rhs):
            return test(lhs, rhs, sheet, dontRecur, >)
        case let .greaterThanEqual(lhs, rhs):
            return test(lhs, rhs, sheet, dontRecur, >=)
        case let .lessThan(lhs, rhs):
            return test(lhs, rhs, sheet, dontRecur, <)
        case let .lessThanEqual(lhs, rhs):
            return test(lhs, rhs, sheet, dontRecur, <=)
        }
    }

    static func toValues(_ operations: [Operation], _ sheet: Sheet, _ dontRecur: [String])
        -> [Value]
    {
        operations.map({ eval(sheet, $0) })
    }

    static func reduce(_ values: [Value], _ fn: (Int, Int) throws -> Int) -> Value {
        var memo: Int?
        var isModifier: Bool?
        for value in values {
            guard let int = value.toInt else { return .undefined }

            if case .modifier = value, isModifier == nil {
                isModifier = true
            } else if case .integer = value, isModifier == nil {
                isModifier = false
            }

            if let prev = memo {
                do {
                    memo = try fn(prev, int)
                } catch {
                    return .undefined
                }
            } else {
                memo = int
            }
        }

        if let isModifier = isModifier, let memo = memo {
            return isModifier ? .modifier(memo) : .integer(memo)
        }
        return .undefined
    }

    static func test(
        _ lhs: Operation, _ rhs: Operation, _ sheet: Sheet, _ dontRecur: [String],
        _ intTest: (Int, Int) -> Bool, _ strTest: (String, String) -> Bool = { _, _ in false }
    ) -> Value {
        let lhsValue = eval(sheet, lhs)
        let rhsValue = eval(sheet, rhs)
        if let lhsInt = lhsValue.toInt,
            let rhsInt = rhsValue.toInt
        {
            return .bool(intTest(lhsInt, rhsInt))
        }

        if let lhsStr = lhsValue.toString,
            let rhsStr = rhsValue.toString
        {
            return .bool(strTest(lhsStr, rhsStr))
        }
        return .undefined
    }

    func toAttributed(_ sheet: Sheet, prevPrecedence: Int = 10) -> AttributedString {
        switch self {
        case let .integer(value):
            return value.description.foreground(.cyan)
        case let .bool(value):
            return value.description.foreground(.yellow)
        case let .dice(dice):
            return dice.toReadable.foreground(.brightBlue)
        case let .string(value):
            return ("\"\(value)\"").foreground(.red)
        case let .modifier(value):
            guard value >= 0 else {
                return value.description.foreground(.blue).bold()
            }
            return "+\(value.description)".foreground(.blue).bold()
        case let .variable(name):
            guard sheet.findOperation(variable: name) != nil else {
                return name.underlined().foreground(.white).background(.red)
            }
            return name.underlined().foreground(.green)
        case let .add(operations):
            return attributedOperator(
                "+", operations: operations, sheet: sheet, precedence: 1, prevPrecedence)
        case let .multiply(operations):
            return attributedOperator(
                "×", operations: operations, sheet: sheet, precedence: 3, prevPrecedence)
        case let .divide(lhs, rhs):
            return attributedOperator(
                "÷", operations: [lhs, rhs], sheet: sheet, precedence: 3, prevPrecedence)
        case let .floor(operation):
            return attributedFunction("floor", operations: [operation], sheet: sheet)
        case let .round(operation):
            return attributedFunction("round", operations: [operation], sheet: sheet)
        case let .ceil(operation):
            return attributedFunction("ceil", operations: [operation], sheet: sheet)
        case let .max(operations):
            return attributedFunction("max", operations: operations, sheet: sheet)
        case let .min(operations):
            return attributedFunction("min", operations: operations, sheet: sheet)

        case let .if(condition, lhs, rhs):
            return attributedFunction("if", operations: [condition, lhs, rhs], sheet: sheet)
        case let .equal(lhs, rhs):
            return attributedOperator(
                "=", operations: [lhs, rhs], sheet: sheet, precedence: 2, prevPrecedence)
        case let .greaterThan(lhs, rhs):
            return attributedOperator(
                ">", operations: [lhs, rhs], sheet: sheet, precedence: 2, prevPrecedence)
        case let .greaterThanEqual(lhs, rhs):
            return attributedOperator(
                ">=", operations: [lhs, rhs], sheet: sheet, precedence: 2, prevPrecedence)
        case let .lessThan(lhs, rhs):
            return attributedOperator(
                "<", operations: [lhs, rhs], sheet: sheet, precedence: 2, prevPrecedence)
        case let .lessThanEqual(lhs, rhs):
            return attributedOperator(
                "<=", operations: [lhs, rhs], sheet: sheet, precedence: 2, prevPrecedence)
        }
    }

    var toEditable: String {
        switch self {
        case let .integer(value):
            return value.description
        case let .dice(dice):
            return dice.toReadable
        case let .bool(value):
            return value.description
        case let .string(value):
            return "\"\(value)\""
        case let .modifier(value):
            guard value >= 0 else {
                return value.description
            }
            return "+\(value.description)"
        case let .variable(name):
            return name
        case let .add(operations):
            return "(+ \(operations.map(\.toEditable).joined(separator: " ")))"
        case let .multiply(operations):
            return "(× \(operations.map(\.toEditable).joined(separator: " ")))"
        case let .divide(lhs, rhs):
            return "(÷ \(lhs.toEditable) \(rhs.toEditable))"
        case let .floor(operation):
            return "(floor \(operation.toEditable))"
        case let .round(operation):
            return "(round \(operation.toEditable))"
        case let .ceil(operation):
            return "(ceil \(operation.toEditable))"
        case let .max(operations):
            return "(max \(operations.map(\.toEditable).joined(separator: " ")))"
        case let .min(operations):
            return "(min \(operations.map(\.toEditable).joined(separator: " ")))"
        case let .if(condition, lhs, rhs):
            return "(if \(condition.toEditable) \(lhs.toEditable) \(rhs.toEditable))"
        case let .equal(lhs, rhs):
            return "(= \(lhs.toEditable) \(rhs.toEditable))"
        case let .greaterThan(lhs, rhs):
            return "(> \(lhs.toEditable) \(rhs.toEditable))"
        case let .greaterThanEqual(lhs, rhs):
            return "(>= \(lhs.toEditable) \(rhs.toEditable))"
        case let .lessThan(lhs, rhs):
            return "(< \(lhs.toEditable) \(rhs.toEditable))"
        case let .lessThanEqual(lhs, rhs):
            return "(<= \(lhs.toEditable) \(rhs.toEditable))"
        }
    }
}

extension Operation: Codable {
    enum CodingKeys: String, CodingKey {
        case type
        case value
        case n
        case d
        case lhs
        case rhs
        case condition
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let type = try values.decode(String.self, forKey: .type)
        switch type {
        case "integer":
            let integer = try values.decode(Int.self, forKey: .value)
            self = .integer(integer)
        case "dice":
            let n = try values.decode(Int.self, forKey: .n)
            let d = try values.decode(Int.self, forKey: .d)
            self = .dice(Dice(n: n, d: d))
        case "bool":
            let bool = try values.decode(Bool.self, forKey: .value)
            self = .bool(bool)
        case "string":
            let string = try values.decode(String.self, forKey: .value)
            self = .string(string)
        case "modifier":
            let modifier = try values.decode(Int.self, forKey: .value)
            self = .modifier(modifier)
        case "variable":
            let variable = try values.decode(String.self, forKey: .value)
            self = .variable(variable)
        case "add":
            let operations = try values.decode([Operation].self, forKey: .value)
            self = .add(operations)
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
        case "round":
            let operation = try values.decode(Operation.self, forKey: .value)
            self = .round(operation)
        case "ceil":
            let operation = try values.decode(Operation.self, forKey: .value)
            self = .ceil(operation)
        case "max":
            let operations = try values.decode([Operation].self, forKey: .value)
            self = .max(operations)
        case "min":
            let operations = try values.decode([Operation].self, forKey: .value)
            self = .min(operations)
        case "if":
            let condition = try values.decode(Operation.self, forKey: .condition)
            let lhs = try values.decode(Operation.self, forKey: .lhs)
            let rhs = try values.decode(Operation.self, forKey: .rhs)
            self = .if(condition, lhs, rhs)
        case "=":
            let lhs = try values.decode(Operation.self, forKey: .lhs)
            let rhs = try values.decode(Operation.self, forKey: .rhs)
            self = .equal(lhs, rhs)
        case ">":
            let lhs = try values.decode(Operation.self, forKey: .lhs)
            let rhs = try values.decode(Operation.self, forKey: .rhs)
            self = .greaterThan(lhs, rhs)
        case ">=":
            let lhs = try values.decode(Operation.self, forKey: .lhs)
            let rhs = try values.decode(Operation.self, forKey: .rhs)
            self = .greaterThanEqual(lhs, rhs)
        case "<":
            let lhs = try values.decode(Operation.self, forKey: .lhs)
            let rhs = try values.decode(Operation.self, forKey: .rhs)
            self = .lessThan(lhs, rhs)
        case "<=":
            let lhs = try values.decode(Operation.self, forKey: .lhs)
            let rhs = try values.decode(Operation.self, forKey: .rhs)
            self = .lessThanEqual(lhs, rhs)
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
        case let .dice(dice):
            try container.encode("dice", forKey: .type)
            try container.encode(dice.n, forKey: .n)
            try container.encode(dice.d, forKey: .d)
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
        case let .round(operation):
            try container.encode("round", forKey: .type)
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
        case let .if(condition, lhs, rhs):
            try container.encode("if", forKey: .type)
            try container.encode(condition, forKey: .condition)
            try container.encode(lhs, forKey: .lhs)
            try container.encode(rhs, forKey: .rhs)
        case let .equal(lhs, rhs):
            try container.encode("=", forKey: .type)
            try container.encode(lhs, forKey: .lhs)
            try container.encode(rhs, forKey: .rhs)
        case let .greaterThan(lhs, rhs):
            try container.encode(">", forKey: .type)
            try container.encode(lhs, forKey: .lhs)
            try container.encode(rhs, forKey: .rhs)
        case let .greaterThanEqual(lhs, rhs):
            try container.encode(">=", forKey: .type)
            try container.encode(lhs, forKey: .lhs)
            try container.encode(rhs, forKey: .rhs)
        case let .lessThan(lhs, rhs):
            try container.encode("<", forKey: .type)
            try container.encode(lhs, forKey: .lhs)
            try container.encode(rhs, forKey: .rhs)
        case let .lessThanEqual(lhs, rhs):
            try container.encode("<=", forKey: .type)
            try container.encode(lhs, forKey: .lhs)
            try container.encode(rhs, forKey: .rhs)
        }
    }
}

private func attributedOperator(
    _ opName: String, operations: [Operation], sheet: Sheet, precedence: Int, _ prevPrecedence: Int
) -> AttributedString {
    let nextPrecedence = precedence > prevPrecedence ? 10 : precedence
    let insides = operations.map({ $0.toAttributed(sheet, prevPrecedence: nextPrecedence) }).reduce(
        AttributedString("")
    ) {
        memo, attributed in
        if memo.isEmpty {
            return attributed
        } else {
            return memo + opName.foreground(.magenta) + attributed
        }
    }
    if precedence > prevPrecedence {
        return "(" + insides + ")"
    } else {
        return insides
    }
}

private func attributedFunction(_ fnName: String, operations: [Operation], sheet: Sheet)
    -> AttributedString
{
    let insides = operations.map({ $0.toAttributed(sheet) }).reduce(AttributedString("")) {
        memo, attributed in
        if memo.isEmpty {
            return attributed
        } else {
            return memo + AttributedString(", ") + attributed
        }
    }
    return
        fnName.foreground(.white)
        + "(".foreground(.brightYellow)
        + insides
        + ")".foreground(.brightYellow)
}
