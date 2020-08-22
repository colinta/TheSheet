////
///  SheetColumn.swift
//

import Ashen

struct SheetColumn {
    enum Message {
        enum Delegate {
            case showControlEditor(Int)
            case relocateControl(Int)
            case stopEditing
        }
        case controlMessage(Int, SheetControl.Message)
        case moveControl(Int, MouseEvent.Direction)
        case delegate(Delegate)
    }

    let title: String
    let controls: [SheetControl]
    let isFormulaColumn: Bool

    init(title: String, controls: [SheetControl], isFormulaColumn: Bool = true) {
        self.title = title
        self.controls = controls
        self.isFormulaColumn = isFormulaColumn
    }

    var formulas: [Formula] {
        Operation.mergeAll(controls.map(\.formulas))
    }

    var canReorder: Bool { !isFormulaColumn }
    var canDelete: Bool { !isFormulaColumn }
    var canAdd: Bool { !isFormulaColumn }

    func replace(title: String) -> SheetColumn {
        SheetColumn(
            title: title,
            controls: controls,
            isFormulaColumn: isFormulaColumn)
    }

    func replace(controls: [SheetControl]) -> SheetColumn {
        SheetColumn(
            title: title,
            controls: controls,
            isFormulaColumn: isFormulaColumn)
    }

    func replace(movingControl: Int?) -> SheetColumn {
        SheetColumn(
            title: title,
            controls: controls,
            isFormulaColumn: isFormulaColumn)
    }

    func update(sheet: Sheet, message: Message) -> (SheetColumn, Sheet.Mod?) {
        switch message {
        case .delegate:
            return (self, nil)
        case let .moveControl(controlIndex, direction):
            let newIndex = direction == .up ? controlIndex - 1 : controlIndex + 1
            guard controlIndex >= 0, controlIndex < controls.count,
                newIndex >= 0, newIndex <= controls.count
            else { return (self, nil) }

            let control = self.controls[controlIndex]
            var controls = self.controls
            controls.remove(at: controlIndex)
            controls.insert(control, at: newIndex)
            return (replace(controls: controls), nil)
        case let .controlMessage(controlIndex, .delegate(.removeControl)):
            guard controlIndex >= 0, controlIndex < controls.count else { return (self, nil) }
            var controls = self.controls
            controls.remove(at: controlIndex)
            return (replace(controls: controls), nil)
        case let .controlMessage(changeIndex, message):
            var mod: Sheet.Mod? = nil
            let controls = self.controls.enumerated().map { (index, control) -> SheetControl in
                guard index == changeIndex else { return control }
                let (newControl, newMod) = control.update(sheet: sheet, message: message)
                mod = newMod
                return newControl
            }
            return (replace(controls: controls), mod)
        }
    }

    func render(_ sheet: Sheet, isEditing: Bool, editingControl: Int?) -> View<SheetColumn.Message>
    {
        let controlViews: [View<SheetColumn.Message>] = controls
            .enumerated().flatMap { controlIndex, control -> [View<SheetColumn.Message>] in
                let controlView = control.render(sheet).map {
                    SheetColumn.Message.controlMessage(controlIndex, $0)
                }.matchContainer(dimension: .width)
                let editableControlView: View<SheetColumn.Message>
                if isEditing {
                    editableControlView = ZStack([
                        controlView,
                        SheetControlEditor(
                            column: self, control: control,
                            controlIndex: controlIndex, lastIndex: controls.count - 1
                        )
                        .matchSize(ofView: controlView),
                    ])
                } else if editingControl == controlIndex {
                    editableControlView = controlView.reversed()
                } else {
                    editableControlView = controlView
                }

                return [
                    editableControlView,
                    Repeating(Text("─".foreground(.black))).height(1),
                ]
            }
        return Stack(
            .down, controlViews)
    }
}

extension SheetColumn: Codable {

    enum CodingKeys: String, CodingKey {
        case title
        case controls
        case isFormulaColumn
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        title = try values.decode(String.self, forKey: .title)
        controls = try values.decode([SheetControl].self, forKey: .controls)
        isFormulaColumn = try values.decode(Bool.self, forKey: .isFormulaColumn)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(controls, forKey: .controls)
        try container.encode(isFormulaColumn, forKey: .isFormulaColumn)
    }
}
