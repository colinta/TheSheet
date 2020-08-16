////
///  Spell.swift
//

struct Dnd5eSpell: Codable {
    let index: String
    let name: String
    let desc: [String]
    let higher_level: [String]
    let range: String
    let components: [String]
    let duration: String
    let concentration: Bool
    let level: Int
    let attack_type: String
}
