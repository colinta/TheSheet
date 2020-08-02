////
///  Action.swift
//

import Ashen

struct Action {
    let title: String
    let check: Formula?
    let damage: [Roll]
    let damageType: String?
    let description: Attributed?

    init(
        title: String, check: Formula? = nil, damage: [Roll] = [], type damageType: String? = nil,
        description: Attributed? = nil
    ) {
        self.title = title
        self.check = check
        self.damage = damage
        self.damageType = damageType
        self.description = description
    }
}
