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

    var modifierOp: Operation {
        .modifier(modifierInt)
    }

    var modifier: Operation.Value {
        .modifier(modifierInt)
    }

    var formulas: [Formula] {
        [
            Formula(
                variable: variableName, operation: .integer(score)),
            Formula(
                variable: "\(variableName).Mod",
                operation: modifierOp),
        ]
    }

    func save(_ sheet: Sheet) -> Operation.Value {
        Operation.if(
            .bool(isProficient),
            .add([modifierOp, .variable("proficiencyBonus")]),
            modifierOp
        ).eval(sheet)
    }

    func replace(score: Int) -> Attribute {
        Attribute(
            title: title, variableName: variableName, score: score, isProficient: isProficient)
    }
}
