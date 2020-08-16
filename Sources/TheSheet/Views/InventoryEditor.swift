////
///  InventoryEditor.swift
//

import Ashen

func InventoryEditor(_ inventory: Inventory) -> View<EditableControl.Message> {
    Input(inventory.title, onChange: { EditableControl.Message.changeString(.title, $0) }, .isResponder(true), .isMultiline(true))
        .padding(bottom: 1)
}
