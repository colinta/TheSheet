////
///  Attribute.swift
//

struct Attribute: Codable {
    let title: String
    let abbreviation: String
    let score: Int
    let isProficient: Bool

    var modifier: Int {
        (score - 10) / 2
    }

    func save(proficiency: Int) -> Int {
        modifier + (isProficient ? proficiency : 0)
    }

    func replace(score: Int) -> Attribute {
        Attribute(
            title: title, abbreviation: abbreviation, score: score, isProficient: isProficient)
    }
}
