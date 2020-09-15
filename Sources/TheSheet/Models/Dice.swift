////
///  Dice.swift
//

struct Dice: Codable {
    let n: Int
    let d: Int

    static let d4 = Dice(n: 1, d: 4)
    static let d6 = Dice(n: 1, d: 6)
    static let d8 = Dice(n: 1, d: 8)
    static let d10 = Dice(n: 1, d: 10)
    static let d12 = Dice(n: 1, d: 12)
    static let d20 = Dice(n: 1, d: 20)

    var toReadable: String {
        guard n > 1 else {
            return "d\(d)"
        }
        return "\(n)d\(d)"
    }
}
