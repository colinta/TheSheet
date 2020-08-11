////
///  Stat.swift
//

struct Stat: Codable {
    let title: String
    let variableName: String?
    let value: Formula

    init(title: String, variableName: String? = nil, value: Formula) {
        self.title = title
        self.variableName = variableName
        self.value = value
    }

    var formulas: Formula.Lookup {
        guard let variableName = variableName else { return [:] }
        return [variableName: value]
    }
}
