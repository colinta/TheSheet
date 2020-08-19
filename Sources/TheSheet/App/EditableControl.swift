////
///  EditableControl.swift
//

import Ashen
import Foundation

enum EditableControl {
    case inventory(Inventory)
    // case action(Action)
    // case ability(Ability)
    // case spellSlots(SpellSlots)
    case pointsTracker(Points, AtXYEditor)
    // case attributes([Attribute])
    case skills([Skill], AtXYEditor)
    // case stats(String, [Stat])
    // case restButtons
    case formulas([Formula.Editable], AtXYEditor)

    indirect enum Message {
        enum Property {
            case title
            case basedOn
            case isProficient
            case variable
            case operation
            case current
            case max
            case resets
        }

        case atPath(IndexPath, Message)
        case firstResponder(IndexPath)
        case noFirstResponder
        case add
        case remove
        case changeString(Property, String)
        case changeInt(Property, Int)
        case changeBool(Property, Bool)
        case togglePointType(Points.PointType)

        static func atIndex(_ index: Int, _ message: Message) -> Message {
            .atPath(IndexPath(index: index), message)
        }
    }

    var control: SheetControl {
        switch self {
        case let .inventory(inventory):
            return .inventory(inventory)
        case let .pointsTracker(points, _):
            return .pointsTracker(points)
        case let .skills(skills, _):
            return .skills(skills)
        case let .formulas(formulas, _):
            return .formulas(
                formulas.compactMap {
                    $0.toFormula()
                })
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

        case let (.skills(skills, editor), .add):
            return .skills(skills + [Skill(title: "", basedOn: "", isProficient: false)], editor)
        case let (.skills(skills, editor), .atPath(path, .remove)):
            return .skills(skills.removingItem(at: path[0]), editor)
        case let (.skills(skills, editor), .atPath(path, .changeString(.title, value))):
            return .skills(
                skills.modifying({ $0.replace(title: value) }, at: path[0]),
                editor)
        case let (.skills(skills, editor), .atPath(path, .changeString(.basedOn, value))):
            return .skills(
                skills.modifying({ $0.replace(basedOn: value) }, at: path[0]), editor.deselect())
        case let (.skills(skills, editor), .atPath(path, .changeBool(.isProficient, value))):
            return .skills(
                skills.modifying({ $0.replace(isProficient: value) }, at: path[0]),
                editor)
        case let (.skills(skills, editor), .firstResponder(path)):
            return .skills(skills, editor.replace(x: path[0], y: path[1]))
        case let (.skills(skills, editor), .noFirstResponder):
            return .skills(skills, editor.deselect())

        case let (.pointsTracker(points, editor), .changeString(.title, value)):
            return .pointsTracker(points.replace(title: value), editor)
        case let (.pointsTracker(points, editor), .changeInt(.current, value)):
            return .pointsTracker(points.replace(current: max(0, value)), editor)
        case let (.pointsTracker(points, editor), .changeInt(.max, value)):
            guard points.max != nil else { return .pointsTracker(points, editor) }
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
                return .pointsTracker(points.replace(types: points.types + [pointType]), editor)
            }
        case let (.pointsTracker(points, editor), .add):
            return .pointsTracker(points.replace(types: points.types + [.other("", "")]), editor)
        case let (.pointsTracker(pointsTracker, editor), .firstResponder(path)):
            return .pointsTracker(pointsTracker, editor.replace(x: path[0], y: path[1]))
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
            return .formulas(formulas.removingItem(at: path[0]), editor)
        case let (.formulas(formulas, editor), .firstResponder(path)):
            return .formulas(formulas, editor.replace(x: path[0], y: path[1]))
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
        default:
            return self
        }
    }

    func render(_ sheet: Sheet) -> View<Message> {
        switch self {
        case let .inventory(inventory):
            return InventoryEditor(inventory)
        case let .skills(skills, editor):
            let basedOn = sheet.formulas.compactMap { formula in
                formula.variable.removingSuffix(".Mod")
            }
            return SkillsEditor(skills, basedOn: basedOn, editor: editor)
        case let .pointsTracker(points, editor):
            return PointsEditor(points, editor: editor)
        case let .formulas(formulas, editor):
            return FormulasEditor(formulas, editor: editor)
        }
    }
}
