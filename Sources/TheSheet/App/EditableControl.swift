////
///  EditableControl.swift
//

import Ashen
import Foundation

enum EditableControl {
    case inventory(Inventory)
    case action(Action, AtPathEditor)
    case pointsTracker(Points, AtPathEditor)
    case skills([Skill], AtPathEditor)
    case formulas([Formula.Editable], AtPathEditor)
    case journal(Journal, AtPathEditor)

    indirect enum Message {
        enum Property {
            case type
            case title
            case level
            case description
            case text
            case basedOn
            case expertise
            case variable
            case operation
            case current
            case max
            case resets
            case check
            case damage
        }

        case atPath(IndexPath, Message)
        case firstResponder(IndexPath)
        case noFirstResponder
        case add
        case remove
        case changeString(Property, String)
        case changeInt(Property, Int)
        case changeBool(Property, Bool)
        case changeExpertise(Property, Skill.Expertise)
        case togglePointType(Points.PointType)

        static func atIndex(_ index: Int, _ message: Message) -> Message {
            .atPath(IndexPath(index: index), message)
        }
    }

    var control: SheetControl {
        switch self {
        case let .inventory(inventory):
            return .inventory(inventory)
        case let .action(action, _):
            return .action(action)
        case let .pointsTracker(points, _):
            return .pointsTracker(points)
        case let .skills(skills, _):
            return .skills(skills)
        case let .formulas(formulas, _):
            return .formulas(
                formulas.compactMap {
                    $0.toFormula()
                })
        case let .journal(journal, _):
            return .journal(journal)
        }
    }

    var canSave: Bool {
        switch self {
        case let .formulas(formulas, _):
            return !formulas.contains(where: { $0.toFormula() == nil })
        default:
            return true
        }
    }

    func update(_ message: Message) -> EditableControl {
        switch (self, message) {
        case let (.inventory(inventory), .changeString(.title, value)):
            return .inventory(inventory.replace(title: value))

        case let (.action(action, editor), .changeString(.title, value)):
            return .action(action.replace(title: value), editor)
        case let (.action(action, editor), .changeString(.level, value)):
            return .action(action.replace(level: value), editor)
        case let (.action(action, editor), .changeString(.description, value)):
            return .action(action.replace(description: value), editor)
        case let (.action(action, editor), .changeString(.current, value)):
            if value == "" {
                return .action(action.replace(remainingUses: nil), editor)
            } else if let value = Int(value) {
                return .action(action.replace(remainingUses: value), editor)
            } else {
                return self
            }
        case let (.action(action, editor), .changeString(.max, value)):
            if value == "" {
                return .action(action.replace(maxUses: nil), editor)
            } else if let value = Int(value) {
                return .action(action.replace(maxUses: .integer(value)), editor)
            } else {
                return self
            }
        case let (.action(action, editor), .firstResponder(path)):
            return .action(action, editor.replace(path: path))
        case let (.action(action, editor), .add):
            let newTitlePath: IndexPath = [action.subactions.count + 1, 0]
            let newSubaction = Action.Sub(title: nil, check: nil, damage: nil, type: nil)
            return .action(
                action.replace(subactions: action.subactions.appending(newSubaction)),
                editor.replace(path: newTitlePath))
        case let (.action(action, editor), .atPath(path, .changeString(.title, value))):
            let index = path[0] - 1
            let subaction = action.subactions[index].replace(title: value.isEmpty ? nil : value)
            return .action(
                action.replace(subactions: action.subactions.replacing(subaction, at: index)),
                editor)
        case let (.action(action, editor), .atPath(path, .changeString(.check, value))):
            let index = path[0] - 1
            let subaction = action.subactions[index]
            guard !value.isEmpty else {
                return .action(
                    action.replace(
                        subactions: action.subactions.replacing(
                            subaction.replace(check: nil), at: index)), editor)
            }
            let op: Operation = (try? Formula.Editable.parse(value)) ?? .editing(value)
            return .action(
                action.replace(
                    subactions: action.subactions.replacing(subaction.replace(check: op), at: index)
                ), editor)
        case let (.action(action, editor), .atPath(path, .changeString(.damage, value))):
            let index = path[0] - 1
            let subaction = action.subactions[index]
            guard !value.isEmpty else {
                return .action(
                    action.replace(
                        subactions: action.subactions.replacing(
                            subaction.replace(damage: nil), at: index)), editor)
            }
            let op: Operation = (try? Formula.Editable.parse(value)) ?? .editing(value)
            return .action(
                action.replace(
                    subactions: action.subactions.replacing(
                        subaction.replace(damage: op), at: index)), editor)
        case let (.action(action, editor), .atPath(path, .changeString(.type, value))):
            let index = path[0] - 1
            let subaction = action.subactions[index].replace(type: value.isEmpty ? nil : value)
            return .action(
                action.replace(subactions: action.subactions.replacing(subaction, at: index)),
                editor)

        case let (.skills(skills, editor), .add):
            return .skills(skills + [Skill(title: "", basedOn: "", expertise: .none)], editor)
        case let (.skills(skills, editor), .atPath(path, .remove)):
            return .skills(skills.removing(at: path[0]), editor)
        case let (.skills(skills, editor), .atPath(path, .changeString(.title, value))):
            return .skills(
                skills.modifying({ $0.replace(title: value) }, at: path[0]),
                editor)
        case let (.skills(skills, editor), .atPath(path, .changeString(.basedOn, value))):
            return .skills(
                skills.modifying({ $0.replace(basedOn: value) }, at: path[0]), editor.deselect())
        case let (.skills(skills, editor), .atPath(path, .changeExpertise(.expertise, value))):
            return .skills(
                skills.modifying({ $0.replace(expertise: value) }, at: path[0]),
                editor)
        case let (.skills(skills, editor), .firstResponder(path)):
            return .skills(skills, editor.replace(path: path))
        case let (.skills(skills, editor), .noFirstResponder):
            return .skills(skills, editor.deselect())

        case let (.pointsTracker(points, editor), .changeString(.title, value)):
            return .pointsTracker(points.replace(title: value), editor)
        case let (.pointsTracker(points, editor), .changeInt(.current, value)):
            return .pointsTracker(points.replace(current: max(0, value)), editor)
        case let (.pointsTracker(points, editor), .changeInt(.max, value)):
            guard points.max != nil else { return self }
            return .pointsTracker(points.replace(max: max(0, value)), editor)
        case let (.pointsTracker(points, editor), .changeBool(.max, enabled)):
            var newPoints = points.replace(max: enabled ? points.max ?? points.current : nil)
            if !enabled {
                newPoints = newPoints.replace(shouldResetOnLongRest: false)
            }
            return .pointsTracker(newPoints, editor)
        case let (.pointsTracker(points, editor), .changeBool(.resets, enabled)):
            return .pointsTracker(points.replace(shouldResetOnLongRest: enabled), editor)
        case let (.pointsTracker(points, editor), .togglePointType(pointType)):
            if points.types.contains(where: { $0.is(pointType) }) {
                return .pointsTracker(
                    points.replace(types: points.types.filter({ !$0.is(pointType) })), editor)
            } else {
                return .pointsTracker(
                    points.replace(types: points.types.appending(pointType)), editor)
            }
        case let (.pointsTracker(points, editor), .add):
            return .pointsTracker(
                points.replace(types: points.types.appending(.other("", ""))), editor)
        case let (.pointsTracker(pointsTracker, editor), .firstResponder(path)):
            return .pointsTracker(pointsTracker, editor.replace(path: path))
        case let (.pointsTracker(points, editor), .atPath(path, .changeString(.title, value))):
            let types: [Points.PointType] = points.types.enumerated().map { index, type in
                guard index == path[0], case let .other(variable, _) = type else { return type }
                return .other(variable, value)
            }
            return .pointsTracker(points.replace(types: types), editor)
        case let (.pointsTracker(points, editor), .atPath(path, .changeString(.variable, value))):
            let types: [Points.PointType] = points.types.enumerated().map { index, type in
                guard index == path[0], case let .other(_, title) = type else { return type }
                return .other(value, title)
            }
            return .pointsTracker(points.replace(types: types), editor)

        case let (.formulas(formulas, editor), .add):
            return .formulas(
                formulas + [Formula.Editable(variable: "name", editableFormula: "formula")],
                editor.replace(x: 0, y: formulas.count))
        case let (.formulas(formulas, editor), .atPath(path, .remove)):
            return .formulas(formulas.removing(at: path[0]), editor)
        case let (.formulas(formulas, editor), .firstResponder(path)):
            return .formulas(formulas, editor.replace(path: path))
        case let (.formulas(formulas, editor), .noFirstResponder):
            return .formulas(formulas, editor.deselect())
        case let (.formulas(formulas, editor), .atPath(path, .changeString(.variable, value))):
            return .formulas(
                formulas.modifying(
                    { formula in
                        formula.replace(variable: value)
                    }, at: path[0]), editor)
        case let (.formulas(formulas, editor), .atPath(path, .changeString(.operation, value))):
            return .formulas(
                formulas.modifying(
                    { formula in
                        formula.replace(editableFormula: value)
                    }, at: path[0]), editor)

        case let (.journal(journal, editor), .firstResponder(path)):
            return .journal(journal, editor.replace(path: path))
        case let (.journal(journal, editor), .changeString(.title, value)):
            return .journal(journal.replace(title: value), editor)
        case let (.journal(journal, editor), .changeString(.text, value)):
            return .journal(journal.replace(text: value), editor)
        default:
            return self
        }
    }

    func render(_ sheet: Sheet) -> View<Message> {
        switch self {
        case let .inventory(inventory):
            return InventoryEditor(inventory)
        case let .action(action, editor):
            return ActionEditor(action, editor)
        case let .skills(skills, editor):
            let basedOn = sheet.formulas.compactMap { formula in
                formula.variable.removingSuffix(".Mod")
            }
            return SkillsEditor(skills, basedOn: basedOn, editor: editor)
        case let .pointsTracker(points, editor):
            return PointsEditor(points, editor: editor)
        case let .formulas(formulas, editor):
            return FormulasEditor(formulas, editor: editor)
        case let .journal(journal, editor):
            return JournalEditor(journal: journal, editor: editor)
        }
    }
}
