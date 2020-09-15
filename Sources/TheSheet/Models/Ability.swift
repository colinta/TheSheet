////
///  Ability.swift
//

struct Ability: Codable {
    struct Uses: Codable {
        let type: Points.PointType
        let amount: Int
    }

    let title: String
    let description: String
    let uses: Uses?
    let isExpanded: Bool

    static let `default` = Ability(title: "", description: "")

    init(title: String, description: String, uses: Uses? = nil, isExpanded: Bool = true) {
        self.title = title
        self.description = description
        self.uses = uses
        self.isExpanded = isExpanded
    }

    func replace(isExpanded: Bool) -> Ability {
        Ability(title: title, description: description, uses: uses, isExpanded: isExpanded)
    }
}
