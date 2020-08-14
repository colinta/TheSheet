////
///  Stat.swift
//

struct Stat: Codable {
    let title: String
    let variableName: String?
    let value: Operation

    init(title: String, variableName: String? = nil, value: Operation) {
        self.title = title
        self.variableName = variableName
        self.value = value
    }

    var formulas: [Formula] {
        guard let variableName = variableName else { return [] }
        return [Formula(variable: variableName, operation: value)]
    }
}
