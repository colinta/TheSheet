////
///  Formula.swift
//

enum Formula {
    case const(Int)
    case modifier(Int)
    case string(String)

    var toReadable: String {
        switch self {
        case let .const(i):
            return "\(i)"
        case let .modifier(i):
            if i >= 0 {
                return "+\(i)"
            }
            return "\(i)"
        case let .string(str):
            return str
        }
    }

    var toReadableRoll: String {
        switch self {
        case let .const(i):
            return "\(i)"
        case let .modifier(i):
            return "\(i)"
        case let .string(str):
            return str
        }
    }
}
