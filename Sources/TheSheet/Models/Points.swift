////
///  Points.swift
//

struct Points: Codable {
    let title: String
    let current: Int
    let max: Int
    let shouldResetOnLongRest: Bool

    func replace(current: Int) -> Points {
        Points(
            title: title, current: current, max: max, shouldResetOnLongRest: shouldResetOnLongRest)
    }

    func replace(max: Int) -> Points {
        Points(
            title: title, current: current, max: max, shouldResetOnLongRest: shouldResetOnLongRest)
    }

    var isSorceryPoints: Bool {
        title == "Sorcery Points"
    }

    var isKiPoints: Bool {
        title == "Ki Points"
    }
}
