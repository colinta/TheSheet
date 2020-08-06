////
///  SheetControl.swift
//

import Ashen

enum SheetControl {
    enum Rest {
        case short
        case long
    }

    enum Message {
        case updateSlots(level: Int, current: Int)
        case burnSlot(level: Int)
        case buySlot(level: Int)
        case updateCount(current: Int, max: Int)
        case takeRest(Rest)
        case contractAction
        case expandAction
    }

    case restButtons
    case slots(String, [Slot])
    case pointsTracker(Points)
    case stats(String, [Stat])
    case action(Action)

    func take(rest: Rest) -> (SheetControl, Sheet.Mod?) {
        var control: SheetControl = self
        switch (self, rest) {
        case let (.restButtons, rest):
            return (
                .restButtons,
                { sheet in
                    sheet.replace(
                        columns: sheet.columns.map { column in
                            column.replace(
                                controls: column.controls.map { control in
                                    control.take(rest: rest).0
                                })
                        })
                }
            )
        case let (.slots(title, slots), .long):
            control = .slots(
                title,
                slots.map { slot in
                    guard slot.shouldResetOnLongRest else { return slot }
                    return Slot(
                        title: slot.title, current: slot.max, max: slot.max,
                        shouldResetOnLongRest: true)
                })
        case let (.pointsTracker(points), .long):
            if points.shouldResetOnLongRest {
                control = .pointsTracker(points.replace(current: points.max))
            }
        default:
            break
        }
        return (control, nil)
    }

    func burnSlot(level: Int) -> Sheet.Mod? {
        let newPoints = Slot.points(forLevel: level)
        return { sheet in
            var canBurn = false
            let newSheet = sheet.replace(
                columns: sheet.columns.map { column in
                    column.replace(
                        controls: column.controls.map { control in
                            if case let .pointsTracker(points) = control, points.isSorceryPoints {
                                return .pointsTracker(
                                    points.replace(current: points.current + newPoints))
                            } else if case let .slots(title, slots) = control,
                                title == "Spell Slots"
                            {
                                return .slots(
                                    title,
                                    slots.enumerated().map { updateLevel, slot in
                                        guard updateLevel == level, slot.current > 0 else {
                                            return slot
                                        }
                                        canBurn = true
                                        return slot.replace(current: slot.current - 1)
                                    })
                            } else {
                                return control
                            }
                        })
                })
            return canBurn ? newSheet : sheet
        }
    }

    func buySlot(level: Int) -> Sheet.Mod? {
        guard let cost = Slot.cost(ofLevel: level) else { return nil }
        return { sheet in
            var canBuy = false
            let newSheet = sheet.replace(
                columns: sheet.columns.map { column in
                    column.replace(
                        controls: column.controls.map { control in
                            if case let .pointsTracker(points) = control, points.isSorceryPoints,
                                points.current >= cost
                            {
                                canBuy = true
                                return .pointsTracker(
                                    points.replace(current: points.current - cost))
                            } else if case let .slots(title, slots) = control,
                                title == "Spell Slots"
                            {
                                return .slots(
                                    title,
                                    slots.enumerated().map { updateLevel, slot in
                                        guard updateLevel == level else { return slot }
                                        return slot.replace(current: slot.current + 1)
                                    })
                            } else {
                                return control
                            }
                        })
                })
            return canBuy ? newSheet : sheet
        }
    }

    func update(_ message: Message) -> (SheetControl, Sheet.Mod?) {
        var control: SheetControl = self

        switch (self, message) {
        case let (.restButtons, .takeRest(type)):
            return take(rest: type)
        case let (.slots(title, slots), .updateSlots(updateLevel, current)):
            control = .slots(
                title,
                slots.enumerated().map { level, slot in
                    guard level == updateLevel else { return slot }
                    return slot.replace(current: current)
                })
        case let (.slots, .burnSlot(level)):
            return (control, burnSlot(level: level))
        case let (.slots, .buySlot(level)):
            return (control, buySlot(level: level))
        case let (.pointsTracker(points), .updateCount(current, max)):
            control = .pointsTracker(points.replace(current: current).replace(max: max))
        case let (.action(action), .contractAction):
            control = .action(action.replace(isExpanded: false))
        case let (.action(action), .expandAction):
            control = .action(action.replace(isExpanded: true))
        default:
            break
        }
        return (control, nil)
    }

    func render(_ sheet: Sheet) -> View<Message> {
        switch self {
        case .restButtons:
            return TakeRestView(Message.takeRest(.short), Message.takeRest(.long))
        case let .slots(title, slots):
            let sorceryPoints = sheet.columns.reduce(0) { memo, column in
                column.controls.reduce(memo) { memo, control in
                    guard case let .pointsTracker(points) = control, points.isSorceryPoints else {
                        return memo
                    }
                    return points.current
                }
            }
            return SlotsView(
                title: title, slots: slots, sorceryPoints: sorceryPoints,
                toggle: { level, current in Message.updateSlots(level: level, current: current) },
                burn: Message.burnSlot,
                buy: Message.buySlot
            )
        case let .pointsTracker(points):
            return PointsTracker(
                points: points, onChange: { c, m in Message.updateCount(current: c, max: m) })
        case let .action(action):
            return ActionView(
                action, action.isExpanded ? Message.contractAction : Message.expandAction)
        case let .stats(title, stats):
            return StatsView(title: title, stats: stats)
        }
    }

}

extension SheetControl: Codable {
    enum Error: Swift.Error {
        case decoding
    }

    enum CodingKeys: String, CodingKey {
        case type
        case title
        case slots
        case points
        case stats
        case action
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let type = try values.decode(String.self, forKey: .type)
        switch type {
        case "restButtons":
            self = .restButtons
        case "slots":
            let title = try values.decode(String.self, forKey: .title)
            let slots = try values.decode([Slot].self, forKey: .slots)
            self = .slots(title, slots)
        case "pointsTracker":
            let points = try values.decode(Points.self, forKey: .points)
            self = .pointsTracker(points)
        case "stats":
            let title = try values.decode(String.self, forKey: .title)
            let stats = try values.decode([Stat].self, forKey: .stats)
            self = .stats(title, stats)
        case "action":
            let action = try values.decode(Action.self, forKey: .action)
            self = .action(action)
        default:
            throw Error.decoding
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .restButtons:
            try container.encode("restButtons", forKey: .type)
        case let .slots(title, slots):
            try container.encode("slots", forKey: .type)
            try container.encode(title, forKey: .title)
            try container.encode(slots, forKey: .slots)
        case let .pointsTracker(points):
            try container.encode("pointsTracker", forKey: .type)
            try container.encode(points, forKey: .points)
        case let .stats(title, stats):
            try container.encode("stats", forKey: .type)
            try container.encode(title, forKey: .title)
            try container.encode(stats, forKey: .stats)
        case let .action(action):
            try container.encode("action", forKey: .type)
            try container.encode(action, forKey: .action)
        }
    }
}
