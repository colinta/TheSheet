////
///  EditableControl.swift
//

import Foundation
import Ashen

enum EditableControl {
    case skills([Skill], AtXYEditor)
    case inventory(Inventory)
    case formulas([Formula.Editable], AtXYEditor)

    indirect enum Message {
        enum Property {
            case title
            case basedOn
            case isProficient
            case variable
            case operation
        }

        case atPath(IndexPath, Message)
        case firstResponder(IndexPath)
        case noFirstResponder
        case add
        case remove
        case changeString(Property, String)
        case changeInt(Property, Int)
        case changeBool(Property, Bool)

        static func atIndex(_ index: Int, _ message: Message) -> Message {
            .atPath(IndexPath(index: index), message)
        }
    }

    var control: SheetControl {
        switch self {
        case let .skills(skills, _):
            return .skills(skills)
        case let .inventory(inventory):
            return .inventory(inventory)
        case let .formulas(formulas, _):
            return .formulas(formulas.compactMap {
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
        case let (.skills(skills, editor), .add):
            return .skills(skills + [Skill(title: "", basedOn: "", isProficient: false)], editor)
        case let (.skills(skills, editor), .atPath(path, .remove)):
            return .skills(skills.removingItem(at: path[0]), editor)
        case let (.skills(skills, editor), .atPath(path, .changeString(.title, value))):
            return .skills(
                skills.modifying({ $0.replace(title: value) }, at: path[0]),
                editor)
        case let (.skills(skills, editor), .atPath(path, .changeString(.basedOn, value))):
            return .skills(skills.modifying({ $0.replace(basedOn: value) }, at: path[0]), editor.deselect())
        case let (.skills(skills, editor), .atPath(path, .changeBool(.isProficient, value))):
            return .skills(
                skills.modifying({ $0.replace(isProficient: value) }, at: path[0]),
                editor)
        case let (.skills(skills, editor), .firstResponder(path)):
            return .skills(skills, editor.replace(x: path[0], y: path[1]))
        case let (.skills(skills, editor), .noFirstResponder):
            return .skills(skills, editor.deselect())

        case let (.inventory(inventory), .changeString(.title, value)):
            return .inventory(inventory.replace(title: value))

        case let (.formulas(formulas, editor), .add):
            return .formulas(formulas + [Formula.Editable(variable: "", operation: "")], editor.replace(x: 0, y: formulas.count))
        case let (.formulas(formulas, editor), .atPath(path, .remove)):
            return .formulas(formulas.removingItem(at: path[0]), editor)
        case let (.formulas(formulas, editor), .firstResponder(path)):
            return .formulas(formulas, editor.replace(x: path[0], y: path[1]))
        case let (.formulas(formulas, editor), .noFirstResponder):
            return .formulas(formulas, editor.deselect())
        case let (.formulas(formulas, editor), .atPath(path, .changeString(.variable, value))):
            return .formulas(formulas.modifying({ formula in
                formula.replace(variable: value)
            }, at: path[0]), editor)
        case let (.formulas(formulas, editor), .atPath(path, .changeString(.operation, value))):
            return .formulas(formulas.modifying({ formula in
                formula.replace(operation: value)
            }, at: path[0]), editor)
        default:
            return self
        }
    }

    func render(_ sheet: Sheet) -> View<Message> {
        switch self {
        case let .skills(skills, editor):
            let basedOn = sheet.formulas.compactMap { formula in
                formula.variable.removingSuffix(".Mod")
            }
            return SkillsEditor(skills, basedOn: basedOn, editor: editor)
        case let .inventory(inventory):
            return InventoryEditor(inventory)
        case let .formulas(formulas, editor):
            return FormulasEditor(formulas, editor: editor)
        }
    }
}
