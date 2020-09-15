////
///  HitDice.swift
//

struct HitDice: Codable {
    let maximum: Operation
    let modifier: Operation
    let remaining: Int
    let d: Int

    func replace(remaining: Int) -> HitDice {
        HitDice(maximum: maximum, modifier: modifier, remaining: remaining, d: d)
    }

    func use(_ delta: Int) -> HitDice {
        HitDice(maximum: maximum, modifier: modifier, remaining: max(0, remaining - delta), d: d)
    }
}
