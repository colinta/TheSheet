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
        case "const":
            let const = try values.decode(Int.self, forKey: .value)
            self = .const(const)
        case "modifier":
            let modifier = try values.decode(Int.self, forKey: .value)
            self = .modifier(modifier)
        case "string":
            let string = try values.decode(String.self, forKey: .value)
            self = .string(string)
        default:
            throw Error.decoding
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .const(const):
            try container.encode("const", forKey: .type)
            try container.encode(const, forKey: .value)
        case let .modifier(modifier):
            try container.encode("modifier", forKey: .type)
            try container.encode(modifier, forKey: .value)
        case let .string(string):
            try container.encode("string", forKey: .type)
            try container.encode(string, forKey: .value)
        }
    }
}
