////
///  Formula
//

import Foundation
import Ashen

struct Formula: Codable {
    let variable: String
    let operation: Operation

    var toEditable: Editable {
        Editable(variable: variable, operation: operation.toEditable)
    }

    struct Editable {
        let variable: String
        let operation: String

        func replace(variable: String) -> Editable {
            Editable(variable: variable, operation: operation)
        }

        func replace(operation: String) -> Editable {
            Editable(variable: variable, operation: operation)
        }

        func toFormula() -> Formula? {
            let parsed = try? Editable.parse(operation)
            // debug("=============== \(#file) line \(#line) ===============")
            // debug("parsed: \(parsed)")
            return parsed.map { Formula(variable: variable, operation: $0) }
        }

        enum Error: Swift.Error {
            case expected(String)
            case unexpected(String)
            case unexpectedEOL
            case notEnoughArgs
            case tooManyArgs
            case parseInt
        }

        static func parse(_ buffer: String) throws -> Operation {
            // debug("=============== \(#file) line \(#line) ===============")
            // debug("--------------- parse ---------------")
            // debug("buffer: \(buffer)")
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

        static func parseOne(_ buffer: String) throws -> (Operation, String) {
            // debug("=============== \(#file) line \(#line) ===============")
            // debug("--------------- parseOne ---------------")
            // debug("buffer: \(buffer)")
            if let buffer = buffer.removingPrefix(" ", "\n") {
                return try parseOne(buffer)
            }
            if let buffer = buffer.removingPrefix("(") {
                return try parseFn(buffer)
            }
            if let buffer = buffer.removingPrefix("\"") {
                let string = try parseString(buffer)
                // debug("===============")
                // debug("string: \(string)")
                return (.string(string), String(buffer.dropFirst(1 + string.count)))
            }
            if let buffer = buffer.removingPrefix("+") {
                let (integer, integerString) = try parseInteger(String(buffer))
                // debug("===============")
                // debug("integer: \(integer)")
                return (.modifier(.integer(integer)), String(buffer.dropFirst(integerString.count)))
            }
            if let buffer = buffer.removingPrefix("--") {
                let (integer, integerString) = try parseInteger(String(buffer))
                // debug("===============")
                // debug("integer: \(integer)")
                return (.modifier(.integer(-integer)), String(buffer.dropFirst(integerString.count)))
            }
            if let buffer = buffer.removingPrefix("-") {
                let (integer, integerString) = try parseInteger(String(buffer))
                // debug("===============")
                // debug("integer: \(integer)")
                return (.integer(-integer), String(buffer.dropFirst(integerString.count)))
            }
            if buffer.hasAnyPrefix("0", "1", "2", "3", "4", "5", "6", "7", "8", "9") {
                let (integer, integerString) = try parseInteger(String(buffer))
                // debug("===============")
                // debug("integer: \(integer)")
                return (.integer(integer), String(buffer.dropFirst(integerString.count)))
            }
            if let char = buffer.first, isVariable(char) {
                let (variable, remainder) = try parseVariable(buffer)
                // debug("===============")
                // debug("variable: \(variable)")
                return (variable, remainder)
            }
            throw Error.unexpected(buffer)
        }

        private static func parseFn(_ buffer: String) throws -> (Operation, String) {
            // debug("=============== \(#file) line \(#line) ===============")
            // debug("--------------- parseFn ---------------")
            // debug("buffer: \(buffer)")
            if let buffer = buffer.removingPrefix(" ", "\n") {
                return try parseFn(buffer)
            }
            if let buffer = buffer.removingPrefix("+") {
                // debug("===============")
                // debug("function: add")
                let (args, remainder) = try parseArgs(buffer)
                // debug("args: \(args)")
                return (.add(args), remainder)
            }
            if let buffer = buffer.removingPrefix("-") {
                // debug("===============")
                // debug("function: subtract")
                let (args, remainder) = try parseArgs(buffer)
                // debug("args: \(args)")
                return (.subtract(args), remainder)
            }
            if let buffer = buffer.removingPrefix("*", "×") {
                // debug("===============")
                // debug("function: multiply")
                let (args, remainder) = try parseArgs(buffer)
                // debug("args: \(args)")
                return (.multiply(args), remainder)
            }
            if let buffer = buffer.removingPrefix("/", "÷") {
                // debug("===============")
                // debug("function: divide")
                let (args, remainder) = try parseArgs(buffer)
                // debug("args: \(args)")
                guard args.count == 2 else {
                    if args.count < 2 { throw Error.notEnoughArgs }
                    throw Error.tooManyArgs
                }
                return (.divide(args[0], args[1]), remainder)
            }
            if let buffer = buffer.removingPrefix("max") {
                // debug("===============")
                // debug("function: max")
                let (args, remainder) = try parseArgs(buffer)
                // debug("args: \(args)")
                return (.max(args), remainder)
            }
            if let buffer = buffer.removingPrefix("min") {
                // debug("===============")
                // debug("function: min")
                let (args, remainder) = try parseArgs(buffer)
                // debug("args: \(args)")
                return (.min(args), remainder)
            }
            if let buffer = buffer.removingPrefix("floor") {
                // debug("===============")
                // debug("function: floor")
                let (args, remainder) = try parseArgs(buffer)
                // debug("args: \(args)")
                guard let arg = args.first, args.count == 1 else {
                    if args.isEmpty { throw Error.notEnoughArgs }
                    throw Error.tooManyArgs
                }
                return (.floor(arg), remainder)
            }
            if let buffer = buffer.removingPrefix("ceil") {
                // debug("===============")
                // debug("function: ceil")
                let (args, remainder) = try parseArgs(buffer)
                // debug("args: \(args)")
                guard let arg = args.first, args.count == 1 else {
                    if args.isEmpty { throw Error.notEnoughArgs }
                    throw Error.tooManyArgs
                }
                return (.ceil(arg), remainder)
            }
            throw Error.unexpected(buffer)
        }

        private static func parseArgs(_ buffer: String) throws -> ([Operation], String) {
            // debug("=============== \(#file) line \(#line) ===============")
            // debug("--------------- parseArgs ---------------")
            // debug("buffer: \(buffer)")
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
            // debug("=============== \(#file) line \(#line) ===============")
            // debug("operation: \(operation)")
            let (args, remainder) = try parseArgs(moreArgs)
            return ([operation] + args, remainder)
        }

        private static func parseString(_ buffer: String) throws -> String {
            // debug("=============== \(#file) line \(#line) ===============")
            // debug("--------------- parseString ---------------")
            // debug("buffer: \(buffer)")
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
            // debug("=============== \(#file) line \(#line) ===============")
            // debug("--------------- parseEscapeString ---------------")
            // debug("buffer: \(buffer)")
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

        private static func parseInteger(_ buffer: String) throws -> (Int, String) {
            // debug("=============== \(#file) line \(#line) ===============")
            // debug("--------------- parseInteger ---------------")
            // debug("buffer: \(buffer)")
            var remainder = buffer
            var integerString = ""
            while true {
                if remainder.isEmpty || remainder.hasAnyPrefix(" ", "\n", ")") { break }
                if remainder.hasAnyPrefix("0", "1", "2", "3", "4", "5", "6", "7", "8", "9"),
                    let char = remainder.first
                {
                    integerString += char.description
                    remainder = String(remainder.dropFirst(1))
                }
                else if integerString.isEmpty {
                    throw Error.unexpected(remainder)
                }
                else {
                    break
                }
            }
            guard let integer = Int(integerString) else {
                throw Error.parseInt
            }
            return (integer, integerString)
        }

        private static func parseVariable(_ buffer: String) throws -> (Operation, String) {
            // debug("=============== \(#file) line \(#line) ===============")
            // debug("--------------- parseVariable ---------------")
            // debug("buffer: \(buffer)")
            var variable = ""
            var remainder = buffer
            while true {
                guard
                    let char = remainder.first,
                    char == "." || isVariable(char)
                else { break }
                variable += char.description
                remainder = String(remainder.dropFirst(1))
            }
            return (.variable(variable), remainder)
        }

        static func isVariable(_ char: Character) -> Bool {
            guard
                char.unicodeScalars.count == 1,
                let unicodeScalar = char.unicodeScalars.first
            else { return false }
            return CharacterSet.letters.contains(unicodeScalar)
        }
    }

    func `is`(named: String) -> Bool {
        variable == named || variable.lowercased() == named.lowercased()
    }
}
