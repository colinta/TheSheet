enum Rest: String, Codable {
    case short
    case long

    static let all: [Rest] = [.short, .long]

    func matches(_ rest: Rest) -> Bool {
        switch self {
        case .short:
            return true
        case .long:
            return rest == .long
        }
    }

    var toString: String {
        switch self {
        case .short:
            return "Short"
        case .long:
            return "Long"
        }
    }
}
