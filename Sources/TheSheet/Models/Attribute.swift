////
///  Attribute.swift
//

struct Attribute: Codable {
    let title: String
    let variableName: String
    let score: Int
    let isProficient: Bool

    var modifierInt: Int {
        (score - 10) / 2
    }

    var modifier: Operation {
        .modifier(modifierInt)
    }

    var formulas: [Formula] {
        [
            Formula(
                variable: variableName, operation: .integer(score)),
            Formula(
                variable: "\(variableName).Mod",
                operation: modifier),
        ]
    }

    var save: Operation {
        Operation.if(
            .bool(isProficient),
            .add([modifier, .variable("proficiencyBonus")]),
            modifier
        )
    }

    func replace(score: Int) -> Attribute {
        Attribute(
            title: title, variableName: variableName, score: score, isProficient: isProficient)
    }
}
