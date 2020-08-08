////
///  Inventory.swift
//

struct Inventory: Codable {
    let title: String
    let quantity: Int?

    func replace(quantity: Int) -> Inventory {
        Inventory(
            title: title, quantity: quantity)
    }
}
