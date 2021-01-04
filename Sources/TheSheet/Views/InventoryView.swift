////
///  SkillsView.swift
//

import Ashen

func InventoryView(
    _ inventory: Inventory, onChange: @escaping (Int) -> ControlMessage,
    onRemove: @escaping @autoclosure SimpleEvent<ControlMessage>
) -> View<ControlMessage> {
    var views: [View<ControlMessage>] = [Text(inventory.title)]
    if let quantity = inventory.quantity {
        views.append(Text("\(quantity) "))
        views.append(OnLeftClick(Text("[-]".foreground(.red)), onChange(-1)))
        views.append(OnLeftClick(Text("[+]".foreground(.green)), onChange(1)))
        views.append(Text(" "))
    }
    views.append(OnLeftClick(Text("[x]".bold().foreground(.red)), onRemove()))
    var isFirst = true
    return Flow(
        .ltr,
        views.map { view in
            if isFirst {
                isFirst = false
                return (.flex1, view)
            } else {
                return (.fixed, view)
            }
        })
}
