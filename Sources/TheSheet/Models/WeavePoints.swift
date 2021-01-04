////
///  WeavePoints.swift
//

struct WeavePoints: Codable {
    let title: String
    let kiUsed: Int
    let sorceryUsed: Int

    var current: Operation { .variable("weavePoints") }
    var max: Operation { .variable("weavePoints.Max") }

    var formulas: [Formula] {
        [
            Formula(variable: "kiUsed", operation: .integer(kiUsed)),
            Formula(variable: "sorceryUsed", operation: .integer(sorceryUsed)),
        ]
    }

    static let `default` = WeavePoints(title: "", kiUsed: 0, sorceryUsed: 0)

    func replace(title: String) -> WeavePoints {
        WeavePoints(title: title, kiUsed: kiUsed, sorceryUsed: sorceryUsed)
    }

    func replace(kiUsed: Int) -> WeavePoints {
        WeavePoints(title: title, kiUsed: kiUsed, sorceryUsed: sorceryUsed)
    }

    func replace(sorceryUsed: Int) -> WeavePoints {
        WeavePoints(title: title, kiUsed: kiUsed, sorceryUsed: sorceryUsed)
    }
}
