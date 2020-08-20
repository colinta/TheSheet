////
///  Formula
//

import Ashen
import Foundation

struct Formula: Codable {
    let variable: String
    let operation: Operation

    var toEditable: Editable {
        Editable(variable: variable, editableFormula: operation.toEditable)
    }

    struct Editable {
        let variable: String
        let editableFormula: String

        func replace(variable: String) -> Editable {
            Editable(variable: variable, editableFormula: editableFormula)
        }

        func replace(editableFormula: String) -> Editable {
            Editable(variable: variable, editableFormula: editableFormula)
        }

        func toFormula() -> Formula? {
            do {
                let parsed = try Editable.parse(editableFormula)
                return Formula(variable: variable, operation: parsed)
            } catch let error {
                debug("=============== \(#file) line \(#line) ===============")
                debug("editableFormula: \(editableFormula)")
                debug("error: \(error)")
                return nil
            }
        }

        enum Error: Swift.Error {
            case expected(String)
            case unexpected(String)
            case unexpectedEOL
            case notEnoughArgs
            case tooManyArgs
            case parseInt
        }
    }

    func `is`(named: String) -> Bool {
        variable == named || variable.lowercased() == named.lowercased()
    }
}

extension Formula.Editable {
    private static func parse(_ buffer: String) throws -> Operation {
        if buffer.hasPrefix("\n") {
            throw Error.unexpectedEOL
        }

        let (operation, remainder) = try parseOne(buffer)
        let trimmed = remainder.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty else {
            throw Error.unexpected(trimmed)
        }
        return operation
    }

    private static func parseOne(_ buffer: String) throws -> (Operation, String) {
        if let buffer = buffer.removingPrefix(" ", "\n") {
            return try parseOne(buffer)
        }
        if let buffer = buffer.removingPrefix("(") {
            return try parseFn(buffer)
        }
        if let buffer = buffer.removingPrefix("\"") {
            let string = try parseString(buffer)
            return (.string(string), String(buffer.dropFirst(1 + string.count)))
        }
        if buffer.hasPrefix("+") || buffer.hasPrefix("-")
            || buffer.hasAnyPrefix("0", "1", "2", "3", "4", "5", "6", "7", "8", "9")
        {
            let (integer, remainder) = try parseInteger(String(buffer))
            return (integer, remainder)
        }
        if let char = buffer.first, isVariable(char) {
            let (variable, remainder) = try parseVariable(buffer)
            return (variable, remainder)
        }
        throw Error.unexpected(buffer)
    }

    private static let functions: [(String, ([Operation]) -> Operation)] = [
        ("+", Operation.add),
        ("*", Operation.multiply),
        ("×", Operation.multiply),
        ("max", Operation.max),
        ("min", Operation.min),
    ]
    private static let arity1: [(String, (Operation) -> Operation)] = [
        ("ceil", Operation.ceil),
        ("floor", Operation.floor),
        ("round", Operation.round),
    ]
    private static let arity2: [(String, (Operation, Operation) -> Operation)] = [
        ("/", Operation.divide),
        ("÷", Operation.divide),
        ("==", Operation.equal),  // must be before "="
        ("=", Operation.equal),
        (">=", Operation.greaterThanEqual),  // must be before ">"
        (">", Operation.greaterThan),
        ("<=", Operation.lessThanEqual),  // must be before "<"
        ("<", Operation.lessThan),
    ]
    private static let arity3: [(String, (Operation, Operation, Operation) -> Operation)] = [
        ("if", Operation.if)
    ]

    private static func parseFn(_ buffer: String) throws -> (Operation, String) {
        if let buffer = buffer.removingPrefix(" ", "\n") {
            return try parseFn(buffer)
        }
        for (match, fn) in functions {
            guard let buffer = buffer.removingPrefix(match) else { continue }
            let (args, remainder) = try parseArgs(buffer)
            return (fn(args), remainder)
        }
        for (match, fn) in arity3 {
            guard let buffer = buffer.removingPrefix(match) else { continue }
            let (args, remainder) = try parseArgs(buffer)
            guard args.count == 3 else {
                if args.count < 3 { throw Error.notEnoughArgs }
                throw Error.tooManyArgs
            }
            return (fn(args[0], args[1], args[2]), remainder)
        }
        for (match, fn) in arity2 {
            guard let buffer = buffer.removingPrefix(match) else { continue }
            let (args, remainder) = try parseArgs(buffer)
            guard args.count == 2 else {
                if args.count < 2 { throw Error.notEnoughArgs }
                throw Error.tooManyArgs
            }
            return (fn(args[0], args[1]), remainder)
        }
        for (match, fn) in arity1 {
            guard let buffer = buffer.removingPrefix(match) else { continue }
            let (args, remainder) = try parseArgs(buffer)
            guard let arg = args.first, args.count == 1 else {
                if args.isEmpty { throw Error.notEnoughArgs }
                throw Error.tooManyArgs
            }
            return (fn(arg), remainder)
        }
        throw Error.unexpected(buffer)
    }

    private static func parseArgs(_ buffer: String) throws -> ([Operation], String) {
        if buffer.isEmpty {
            throw Error.expected(")")
        }
        if let buffer = buffer.removingPrefix(")") {
            return ([], buffer)
        }
        if let buffer = buffer.removingPrefix(" ", "\n") {
            return try parseArgs(buffer)
        }
        let (operation, moreArgs) = try parseOne(buffer)
        let (args, remainder) = try parseArgs(moreArgs)
        return ([operation] + args, remainder)
    }

    private static func parseString(_ buffer: String) throws -> String {
        if buffer.hasPrefix("\"") {
            return ""
        }
        if let buffer = buffer.removingPrefix("\\") {
            return try parseEscapeString(buffer)
        }
        guard let char = buffer.first else {
            throw Error.expected("\"")
        }
        return char.description + (try parseString(buffer))
    }

    private static func parseEscapeString(_ buffer: String) throws -> String {
        if let buffer = buffer.removingPrefix("\"") {
            return "\"" + (try parseEscapeString(buffer))
        }
        if let buffer = buffer.removingPrefix("\\") {
            return "\\" + (try parseEscapeString(buffer))
        }
        if let buffer = buffer.removingPrefix("n") {
            return "\n" + (try parseEscapeString(buffer))
        }
        if let buffer = buffer.removingPrefix("t") {
            return "\t" + (try parseString(buffer))
        }
        return "\\" + (try parseString(buffer))
    }

    private static func parseInteger(_ buffer: String) throws -> (Operation, String) {
        let isModifier: Bool
        let multiplier: Int
        let intBuffer: String
        if let buffer = buffer.removingPrefix("+") {
            isModifier = true
            intBuffer = buffer
            multiplier = 1
        } else if let buffer = buffer.removingPrefix("-") {
            isModifier = false
            intBuffer = buffer
            multiplier = -1
        } else {
            isModifier = false
            intBuffer = buffer
            multiplier = 1
        }
        var remainder = intBuffer
        var integerString = ""
        while true {
            if remainder.isEmpty || remainder.hasAnyPrefix(" ", "\n", ")") { break }
            if remainder.hasAnyPrefix("0", "1", "2", "3", "4", "5", "6", "7", "8", "9"),
                let char = remainder.first
            {
                integerString += char.description
                remainder = String(remainder.dropFirst(1))
            } else if remainder.hasPrefix("d"), let n = Int(integerString) {
                if isModifier || multiplier == -1 {
                    throw Error.unexpected(remainder)
                }

                let (varOperation, varRemainder) = try parseVariable(remainder)
                if case .variable = varOperation {
                    return (.multiply([.integer(n), varOperation]), varRemainder)
                } else if case let .dice(dice) = varOperation {
                    return (.dice(dice), varRemainder)
                }
                throw Error.unexpected(remainder)
            } else if integerString.isEmpty {
                throw Error.unexpected(remainder)
            } else {
                break
            }
        }
        guard let integer = Int(integerString) else {
            throw Error.parseInt
        }
        if isModifier {
            return (.modifier(multiplier * integer), integerString)
        }
        return (.integer(multiplier * integer), remainder)
    }

    private static func parseVariable(_ buffer: String) throws -> (Operation, String) {
        var variable = ""
        var remainder = buffer
        while true {
            guard
                let char = remainder.first,
                isVariable(char)
            else { break }
            variable += char.description
            remainder = String(remainder.dropFirst(1))
        }
        if variable == "true" {
            return (.bool(true), remainder)
        }
        if variable == "false" {
            return (.bool(false), remainder)
        }
        if let remainder = remainder.removingPrefix("d"), let dice = Int(remainder) {
            return (.dice(Operation.Dice(n: 1, d: dice)), remainder)
        }
        return (.variable(variable), remainder)
    }

    static func isVariable(_ char: Character) -> Bool {
        guard
            char.unicodeScalars.count == 1,
            let unicodeScalar = char.unicodeScalars.first
        else { return false }
        return char == "." || CharacterSet.letters.contains(unicodeScalar)
            || CharacterSet.decimalDigits.contains(unicodeScalar)
    }
}
