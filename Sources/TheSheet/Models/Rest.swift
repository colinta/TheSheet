enum Rest: String, Codable {
    case short
    case long

    static let all: [Rest] = [.short, .long]

    var toString: String {
        switch self {
        case .short:
            return "Short"
        case .long:
            return "Long"
        }
    }
}
