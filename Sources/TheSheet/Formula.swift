////
///  Formula.swift
//

enum Formula {
    case int(Int)
    case mod(Int)
    case string(String)

    var toReadable: String {
        switch self {
        case let .int(i):
            return "\(i)"
        case let .mod(i):
            if i >= 0 {
                return "+\(i)"
            }
            return "\(i)"
        case let .string(str):
            return str
        }
    }
}
