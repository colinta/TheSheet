////
///  Attribute.swift
//

struct Attribute: Codable {
    let title: String
    let variableName: String
    let score: Int
    let isProficient: Bool

    var modifier: Int {
        (score - 10) / 2
    }

    var formulas: [Formula] {
        [
            Formula(
                variable: variableName, operation: .integer(score)),
            Formula(
                variable: "\(variableName).Mod",
                operation: .modifier(modifier)),
        ]
    }

    func save(proficiencyBonus: Int) -> Int {
        modifier + (isProficient ? proficiencyBonus : 0)
    }

    func replace(score: Int) -> Attribute {
        Attribute(
            title: title, variableName: variableName, score: score, isProficient: isProficient)
    }
}
