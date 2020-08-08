////
///  SkillsView.swift
//

import Ashen

func InventoryView<Msg>(
    _ inventory: Inventory, onChange: @escaping (Int) -> Msg,
    onRemove: @escaping @autoclosure SimpleEvent<Msg>
) -> View<Msg> {
    var views: [View<Msg>] = [Text(inventory.title)]
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
