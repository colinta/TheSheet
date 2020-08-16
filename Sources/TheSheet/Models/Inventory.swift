////
///  Inventory.swift
//

struct Inventory: Codable {
    let title: String
    let quantity: Int?

    func replace(title: String) -> Inventory {
        Inventory(
            title: title, quantity: quantity)
    }

    func replace(quantity: Int) -> Inventory {
        Inventory(
            title: title, quantity: quantity)
    }
}
