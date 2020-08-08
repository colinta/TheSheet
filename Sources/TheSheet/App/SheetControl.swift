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
        case updateSlotCurrent(level: Int, current: Int)
        case updateSlotMax(level: Int, max: Int)
        case burnSlot(level: Int)
        case buySlot(level: Int)
        case updatePoints(current: Int, max: Int?)
        case collapseAction
        case expandAction
        case changeQuantity(delta: Int)
        case changeAttribute(index: Int, delta: Int)
        case resetActionUses
        case takeRest(Rest)
        case removeControl
    }

    case slots(String, [Slot])
    case pointsTracker(Points)
    case stats(String, [Stat])
    case attributes([Attribute])
    case skills([Skill])
    case action(Action)
    case inventory(Inventory)
    case restButtons

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
            if points.shouldResetOnLongRest, let pointsMax = points.max {
                control = .pointsTracker(points.replace(current: pointsMax))
            }
        case let (.action(action), .long):
            if action.shouldResetOnLongRest, let uses = action.uses {
                control = .action(action.replace(remainingUses: uses))
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
        case let (.slots(title, slots), .updateSlotCurrent(updateLevel, newCurrent)):
            control = .slots(
                title,
                slots.enumerated().map { level, slot in
                    guard level == updateLevel, newCurrent != slot.current else { return slot }
                    return slot.replace(current: newCurrent)
                })
        case let (.slots(title, slots), .updateSlotMax(updateLevel, newMax)):
            control = .slots(
                title,
                slots.enumerated().map { level, slot in
                    guard level == updateLevel, newMax >= 0, newMax != slot.max else { return slot }
                    let newCurrent: Int
                    if newMax > slot.max, slot.current == slot.max {
                        newCurrent = slot.current + 1
                    } else if slot.current > 0, slot.current == slot.max {
                        newCurrent = max(0, slot.current - 1)
                    } else {
                        newCurrent = slot.current
                    }
                    return slot.replace(max: newMax).replace(current: newCurrent)
                })
        case let (.slots, .burnSlot(level)):
            return (control, burnSlot(level: level))
        case let (.slots, .buySlot(level)):
            return (control, buySlot(level: level))
        case let (.pointsTracker(points), .updatePoints(current, max)):
            control = .pointsTracker(points.replace(current: current).replace(max: max))
        case let (.action(action), .collapseAction):
            control = .action(action.replace(isExpanded: false))
        case let (.action(action), .expandAction):
            control = .action(action.replace(isExpanded: true))
        case let (.attributes(attributes), .changeAttribute(changeIndex, delta)):
            guard changeIndex >= 0, changeIndex < attributes.count else { break }
            control = .attributes(
                attributes.enumerated().map { index, attribute in
                    guard index == changeIndex else { return attribute }
                    return attribute.replace(score: attribute.score + delta)
                })
        case let (.action(action), .changeQuantity(delta)):
            guard let remainingUses = action.remainingUses else { break }
            control = .action(action.replace(remainingUses: max(0, remainingUses + delta)))
        case let (.action(action), .resetActionUses):
            guard let uses = action.uses else { break }
            control = .action(action.replace(remainingUses: uses))
        case let (.inventory(inventory), .changeQuantity(delta)):
            guard let quantity = inventory.quantity else { break }
            control = .inventory(inventory.replace(quantity: max(0, quantity + delta)))
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
                onToggle: Message.updateSlotCurrent,
                onChangeMax: Message.updateSlotMax,
                onBurn: Message.burnSlot,
                onBuy: Message.buySlot
            )
        case let .pointsTracker(points):
            return PointsTracker(
                points: points, onChange: { c, m in Message.updatePoints(current: c, max: m) })
        case let .action(action):
            return ActionView(
                action,
                onExpand: action.isExpanded ? Message.collapseAction : Message.expandAction,
                onChange: Message.changeQuantity,
                onResetUses: Message.resetActionUses)
        case let .stats(title, stats):
            return StatsView(title: title, stats: stats)
        case let .attributes(attributes):
            return AttributesView(attributes, onChange: Message.changeAttribute)
        case let .skills(skills):
            return SkillsView(skills.map { $0.resolve(sheet) })
        case let .inventory(inventory):
            return InventoryView(
                inventory, onChange: Message.changeQuantity, onRemove: Message.removeControl)
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
        case attributes
        case skills
        case action
        case inventory
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
        case "attributes":
            let attributes = try values.decode([Attribute].self, forKey: .attributes)
            self = .attributes(attributes)
        case "skills":
            let skills = try values.decode([Skill].self, forKey: .skills)
            self = .skills(skills)
        case "inventory":
            let inventory = try values.decode(Inventory.self, forKey: .inventory)
            self = .inventory(inventory)
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
        case let .attributes(attributes):
            try container.encode("attributes", forKey: .type)
            try container.encode(attributes, forKey: .attributes)
        case let .skills(skills):
            try container.encode("skills", forKey: .type)
            try container.encode(skills, forKey: .skills)
        case let .inventory(inventory):
            try container.encode("inventory", forKey: .type)
            try container.encode(inventory, forKey: .inventory)
        }
    }
}
