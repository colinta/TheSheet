////
///  SheetControl.swift
//

import Ashen

enum SheetControl {
    case inventory(Inventory)
    case action(Action)
    case ability(Ability)
    case spellSlots(SpellSlots)
    case pointsTracker(Points)
    case attributes([Attribute])
    case skills([Skill])
    case stats(String, [Stat])
    case hitDice([HitDice])
    case restButton
    case formulas([Formula])
    case journal(Journal)

    static var all: [(String, SheetControl)] = [
        ("Inventory", .inventory(Inventory(title: "", quantity: nil))),
        ("Action (Weapon, Spell)", .action(Action(title: ""))),
        (
            "Spell Slots",
            .spellSlots(.default)
        ),
        (
            "Ability",
            .ability(.default)
        ),
        (
            "Points Tracker (Hit Points, Ki, …)",
            .pointsTracker(.default)
        ),
        ("Attributes (Strength, Charisma, …)", .attributes([])),
        ("Skills (Acrobatics, Stealth, …)", .skills([])),
        ("Stats (Armor, Attack, …)", .stats("", [])),
        ("Hit Dice", .hitDice([])),
        ("Take a Rest", .restButton),
        ("Journal", .journal(.default)),
    ]

    var canEdit: Bool { editor != nil }
    var formulas: [Formula] {
        switch self {
        case let .attributes(attributes):
            return Operation.mergeAll(attributes.map { $0.formulas })
        case let .stats(_, stats):
            return Operation.mergeAll(stats.map { $0.formulas })
        case let .formulas(formulas):
            return formulas
        case let .pointsTracker(points):
            return points.formulas
        default:
            return []
        }
    }

    var editor: EditableControl? {
        switch self {
        case let .inventory(inventory):
            return .inventory(inventory)
        case let .action(action):
            return .action(action, AtPathEditor(atPath: [0, 0]))
        case let .pointsTracker(points):
            return .pointsTracker(points, AtPathEditor(atPath: [0, 0]))
        case let .skills(skills):
            return .skills(skills, AtPathEditor(atPath: nil))
        case let .formulas(formulas):
            return .formulas(formulas.map(\.toEditable), AtPathEditor(atPath: nil))
        case let .journal(journal):
            return .journal(journal, AtPathEditor(atPath: [0]))
        default:
            return nil
        }
    }

    enum Message {
        enum Delegate {
            case removeControl
            case roll(Roll)
            case command(Command<Message>)
        }
        case updateSlotCurrent(slotIndex: Int, current: Int)
        case updateSlotMax(slotIndex: Int, max: Int)
        case burnSlot(slotIndex: Int)
        case buySlot(slotIndex: Int)
        case updatePoints(current: Int)
        case toggleExpanded
        case changeQuantity(delta: Int)
        case changeQuantityAtIndex(index: Int, delta: Int)
        case useHitDie(Int)
        case changeHitDie(Int, delta: Int)
        case resetActionUses
        case takeRest(Rest)
        case delegate(Delegate)
    }

    func update(sheet: Sheet, message: Message) -> (SheetControl, Sheet.Mod?) {
        var control: SheetControl = self

        switch (self, message) {
        case let (.inventory(inventory), .changeQuantity(delta)):
            guard let quantity = inventory.quantity else { break }
            control = .inventory(inventory.replace(quantity: max(0, quantity + delta)))
        case let (.action(action), .toggleExpanded):
            control = .action(action.replace(isExpanded: !action.isExpanded))
        case let (.action(action), .changeQuantity(delta)):
            guard let remainingUses = action.remainingUses else { break }
            control = .action(action.replace(remainingUses: max(0, remainingUses + delta)))
        case let (.action(action), .resetActionUses):
            guard let maxUses = action.maxUses,
                let value = maxUses.eval(sheet).toInt
            else { break }
            control = .action(action.replace(remainingUses: value))
        case let (.ability(ability), .toggleExpanded):
            control = .ability(ability.replace(isExpanded: !ability.isExpanded))
        case let (.ability(ability), .changeQuantity(delta)):
            guard let uses = ability.uses else { break }
            return (.ability(ability), SheetControl.spend(type: uses.type, amount: delta))
        case let (.spellSlots(spellSlots), .updateSlotCurrent(updateSlotIndex, newCurrent)):
            let newSlots = spellSlots.slots.enumerated().map { slotIndex, slot -> SpellSlot in
                guard slotIndex == updateSlotIndex, newCurrent != slot.current else {
                    return slot
                }
                return slot.replace(current: newCurrent)
            }
            control = .spellSlots(spellSlots.replace(slots: newSlots))
        case let (.spellSlots(spellSlots), .updateSlotMax(updateSlotIndex, newMax)):
            let modifiedSpellSlots: [SpellSlot]
            if newMax > 0, updateSlotIndex == spellSlots.slots.count,
                let last = spellSlots.slots.last, last.max > 0, let lastLevel = Int(last.title),
                lastLevel < 9
            {
                modifiedSpellSlots =
                    spellSlots.slots + [SpellSlot(title: "\(lastLevel + 1)", current: 1, max: 1)]
            } else {
                modifiedSpellSlots = spellSlots.slots.enumerated().map { slotIndex, slot in
                    guard slotIndex == updateSlotIndex, newMax >= 0, newMax != slot.max else {
                        return slot
                    }

                    let newCurrent: Int
                    if newMax > slot.max, slot.current == slot.max {
                        newCurrent = slot.current + 1
                    } else if slot.current > 0, slot.current == slot.max {
                        newCurrent = max(0, slot.current - 1)
                    } else {
                        newCurrent = slot.current
                    }
                    return slot.replace(max: newMax).replace(current: newCurrent)
                }
            }

            control = .spellSlots(spellSlots.replace(slots: modifiedSpellSlots))
        case let (.spellSlots, .burnSlot(slotIndex)):
            return (control, SheetControl.burnSlot(slotIndex: slotIndex))
        case let (.spellSlots, .buySlot(slotIndex)):
            return (control, SheetControl.buySlot(slotIndex: slotIndex))
        case let (.pointsTracker(points), .updatePoints(current)):
            control = .pointsTracker(points.replace(current: current))
        case let (.attributes(attributes), .changeQuantityAtIndex(changeIndex, delta)):
            guard changeIndex >= 0, changeIndex < attributes.count else { break }
            control = .attributes(
                attributes.enumerated().map { index, attribute in
                    guard index == changeIndex else { return attribute }
                    return attribute.replace(score: attribute.score + delta)
                })
        case let (.hitDice(hitDice), .useHitDie(atIndex)):
            control = .hitDice(hitDice.enumerated().map { index, hitDie in
                guard atIndex == index else { return hitDie }
                return hitDie.use(1)
            })
        case let (.hitDice(hitDice), .changeHitDie(atIndex, delta)):
            control = .hitDice(hitDice.enumerated().map { index, hitDie in
                guard atIndex == index else { return hitDie }
                return hitDie.use(-delta)
            })
        case let (.restButton, .takeRest(rest)):
            return (
                .restButton,
                Sheet.mapControls { control in
                    control.takeRest(sheet: sheet, rest: rest)
                }
            )
        case let (.journal(journal), .toggleExpanded):
            control = .journal(journal.replace(isExpanded: !journal.isExpanded))
        default:
            break
        }
        return (control, nil)
    }

    func render(_ sheet: Sheet) -> View<Message> {
        switch self {
        case let .inventory(inventory):
            return InventoryView(
                inventory, onChange: Message.changeQuantity,
                onRemove: Message.delegate(.removeControl))
        case let .action(action):
            return ActionView(
                action, sheet: sheet,
                onExpand: Message.toggleExpanded,
                onChange: Message.changeQuantity,
                onResetUses: Message.resetActionUses,
                onRoll: { Message.delegate(.roll($0)) })
        case let .ability(ability):
            return AbilityView(
                ability, onExpand: Message.toggleExpanded, onChange: Message.changeQuantity
            )
        case let .spellSlots(spellSlots):
            let sorceryPoints = sheet.columns.reduce(0) { memo, column in
                column.controls.reduce(memo) { memo, control in
                    guard case let .pointsTracker(points) = control, points.is(.sorcery) else {
                        return memo
                    }
                    return points.current
                }
            }
            let modifiedSpellSlots: [SpellSlot]
            if let last = spellSlots.slots.last, last.max > 0, last.max < 9,
                let lastLevel = Int(last.title)
            {
                modifiedSpellSlots =
                    spellSlots.slots + [SpellSlot(title: "\(lastLevel + 1)", current: 0, max: 0)]
            } else {
                modifiedSpellSlots = spellSlots.slots
            }
            return SpellSlotsView(
                title: spellSlots.title, spellSlots: modifiedSpellSlots,
                sorceryPoints: sorceryPoints,
                onToggle: Message.updateSlotCurrent,
                onChangeMax: Message.updateSlotMax,
                onBurn: Message.burnSlot,
                onBuy: Message.buySlot
            )
        case let .pointsTracker(points):
            return PointsTracker(
                points: points, sheet: sheet, onChange: Message.updatePoints)
        case let .stats(title, stats):
            return StatsView(
                title: title, stats: stats, sheet: sheet, onRoll: { Message.delegate(.roll($0)) })
        case let .attributes(attributes):
            return AttributesView(
                attributes, sheet: sheet, onChange: Message.changeQuantityAtIndex,
                onRoll: { Message.delegate(.roll($0)) })
        case let .skills(skills):
            return SkillsView(skills.map { $0.resolve(sheet) })
        case let .formulas(formulas):
            let sheetFormulas = sheet.formulas.filter { sf in
                !formulas.contains(where: { ff in ff.is(named: sf.variable) })
            }.sorted { lhs, rhs in
                lhs.variable.lowercased() < rhs.variable.lowercased()
            }
            return FormulasView(editable: formulas, fixed: sheetFormulas, sheet: sheet)
        case let .journal(journal):
            return JournalView(journal: journal, onExpand: Message.toggleExpanded)
        case let .hitDice(hitDice):
            return HitDiceView(hitDice: hitDice, sheet: sheet,
                onUse: { index, roll in
                    .delegate(.command(
                        Command<SheetControl.Message>.list([
                            Send(.useHitDie(index)),
                            Send(.delegate(.roll(roll))),
                        ])
                    ))
                },
                onChange: SheetControl.Message.changeHitDie
            )
        case .restButton:
            return TakeRestView(Message.takeRest)
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
        case inventory
        case action
        case ability
        case spellSlots
        case points
        case attributes
        case skills
        case stats
        case hitDice
        case formulas
        case journal
        case isExpanded
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let type = try values.decode(String.self, forKey: .type)
        switch type {
        case "inventory":
            let inventory = try values.decode(Inventory.self, forKey: .inventory)
            self = .inventory(inventory)
        case "action":
            let action = try values.decode(Action.self, forKey: .action)
            self = .action(action)
        case "ability":
            let ability = try values.decode(Ability.self, forKey: .ability)
            self = .ability(ability)
        case "spellSlots":
            let spellSlots = try values.decode(SpellSlots.self, forKey: .spellSlots)
            self = .spellSlots(spellSlots)
        case "pointsTracker":
            let points = try values.decode(Points.self, forKey: .points)
            self = .pointsTracker(points)
        case "attributes":
            let attributes = try values.decode([Attribute].self, forKey: .attributes)
            self = .attributes(attributes)
        case "skills":
            let skills = try values.decode([Skill].self, forKey: .skills)
            self = .skills(skills)
        case "stats":
            let title = try values.decode(String.self, forKey: .title)
            let stats = try values.decode([Stat].self, forKey: .stats)
            self = .stats(title, stats)
        case "hitDice":
            let hitDice = try values.decode([HitDice].self, forKey: .hitDice)
            self = .hitDice(hitDice)
        case "restButton":
            self = .restButton
        case "formulas":
            let formulas = try values.decode([Formula].self, forKey: .formulas)
            self = .formulas(formulas)
        case "journal":
            let journal = try values.decode(Journal.self, forKey: .journal)
            self = .journal(journal)
        default:
            throw Error.decoding
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .inventory(inventory):
            try container.encode("inventory", forKey: .type)
            try container.encode(inventory, forKey: .inventory)
        case let .action(action):
            try container.encode("action", forKey: .type)
            try container.encode(action, forKey: .action)
        case let .ability(ability):
            try container.encode("ability", forKey: .type)
            try container.encode(ability, forKey: .ability)
        case let .spellSlots(spellSlots):
            try container.encode("spellSlots", forKey: .type)
            try container.encode(spellSlots, forKey: .spellSlots)
        case let .pointsTracker(points):
            try container.encode("pointsTracker", forKey: .type)
            try container.encode(points, forKey: .points)
        case let .attributes(attributes):
            try container.encode("attributes", forKey: .type)
            try container.encode(attributes, forKey: .attributes)
        case let .skills(skills):
            try container.encode("skills", forKey: .type)
            try container.encode(skills, forKey: .skills)
        case let .stats(title, stats):
            try container.encode("stats", forKey: .type)
            try container.encode(title, forKey: .title)
            try container.encode(stats, forKey: .stats)
        case let .hitDice(hitDice):
            try container.encode("hitDice", forKey: .type)
            try container.encode(hitDice, forKey: .hitDice)
        case .restButton:
            try container.encode("restButton", forKey: .type)
        case let .formulas(formulas):
            try container.encode("formulas", forKey: .type)
            try container.encode(formulas, forKey: .formulas)
        case let .journal(journal):
            try container.encode("journal", forKey: .type)
            try container.encode(journal, forKey: .journal)
        }
    }
}
extension SheetControl {
    private func takeRest(sheet: Sheet, rest: Rest) -> SheetControl {
        var control: SheetControl = self
        switch self {
        case let .spellSlots(spellSlots):
            guard spellSlots.shouldResetOnLongRest, rest == .long else { break }
            control = .spellSlots(
                spellSlots.replace(
                    slots: spellSlots.slots.map { slot in
                        return SpellSlot(
                            title: slot.title, current: slot.max, max: slot.max)
                    }))
        case let .pointsTracker(points):
            guard points.shouldResetOn?.matches(rest) == true, let pointsMax = points.max?.eval(sheet).toInt else { break }
            control = .pointsTracker(points.replace(current: pointsMax))
        case let .action(action):
            guard
                action.shouldResetOn?.matches(rest) == true,
                let maxUses = action.maxUses,
                let value = maxUses.eval(sheet).toInt
            else { break }
            control = .action(action.replace(remainingUses: value))
        case let .hitDice(hitDice):
            control = .hitDice(hitDice.map { hitDie in
                guard let maxDice = hitDie.maximum.eval(sheet).toInt else { return hitDie }
                return hitDie.replace(remaining: maxDice)
            })
        default:
            break
        }
        return control
    }

    private static func burnSlot(slotIndex: Int) -> Sheet.Mod {
        let newPoints = SpellSlot.points(forLevel: slotIndex + 1)
        return { sheet in
            var canBurn = false
            return sheet.mapControls { control in
                guard case let .spellSlots(spellSlots) = control else { return control }
                return .spellSlots(
                    spellSlots.replace(
                        slots: spellSlots.slots.enumerated().map {
                            updateSlotIndex, slot in
                            guard updateSlotIndex == slotIndex, slot.current > 0
                            else {
                                return slot
                            }
                            canBurn = true
                            return slot.replace(current: slot.current - 1)
                        }))
            }.mapControls { control in
                guard canBurn, case let .pointsTracker(points) = control, points.is(.sorcery) else {
                    return control
                }
                return .pointsTracker(
                    points.replace(current: points.current + newPoints))
            }
        }
    }

    private static func buySlot(slotIndex: Int) -> Sheet.Mod? {
        guard let cost = SpellSlot.cost(ofLevel: slotIndex + 1) else { return nil }
        return { sheet in
            var canBuy = false
            return sheet.mapControls { control in
                guard case let .pointsTracker(points) = control,
                    points.is(.sorcery),
                    points.current >= cost
                else { return control }
                canBuy = true
                return .pointsTracker(
                    points.replace(current: points.current - cost))
            }.mapControls { control in
                guard canBuy, case let .spellSlots(spellSlots) = control else { return control }
                return .spellSlots(
                    spellSlots.replace(
                        slots: spellSlots.slots.enumerated().map {
                            updateSlotIndex, slot in
                            guard updateSlotIndex == slotIndex else { return slot }
                            return slot.replace(current: slot.current + 1)
                        }))
            }
        }
    }

    private static func spend(type pointsType: Points.PointType, amount: Int) -> Sheet.Mod {
        return { sheet in
            sheet.mapControls { control in
                guard case let .pointsTracker(points) = control,
                    points.is(pointsType),
                    points.current >= amount
                else { return control }
                return .pointsTracker(
                    points.replace(current: points.current - amount))
            }
        }
    }

}
