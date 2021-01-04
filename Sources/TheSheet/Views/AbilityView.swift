////
///  AbilityView.swift
//

import Ashen

func AbilityView(
    _ ability: Ability, onExpand: @escaping @autoclosure SimpleEvent<ControlMessage>,
    onChange: @escaping (Int) -> ControlMessage
) -> View<ControlMessage> {
    let expandedViews: [View<ControlMessage>]
    let buttonView: View<ControlMessage>
    let abilityStats: View<ControlMessage>? = _AbilityDescriptionView(
        ability, onChange)
    if abilityStats == nil {
        buttonView = Space()
        expandedViews = []
    } else if let abilityStats = abilityStats, ability.isExpanded {
        expandedViews = [abilityStats]
        buttonView = OnLeftClick(
                    Text("↑↑↑").bold().aligned(.topRight), onExpand())
    } else {
        buttonView = OnLeftClick(
                    Text("↓↓↓").bold().aligned(.topRight), onExpand())
        expandedViews = []
    }
    return Stack(
        .down,
        [
            ZStack(
                _AbilityTitleView(ability.title),
                buttonView
            ).matchContainer(dimension: .width)
        ] + expandedViews
    ).border(.single)
}

func _AbilityDescriptionView(
    _ ability: Ability, _ onChange: @escaping (Int) -> ControlMessage
) -> View<ControlMessage>? {
    var abilityViews: [View<ControlMessage>] = [_AbilityDescriptionView(ability.description)]

    if let uses = ability.uses {
        let abilityUses: View<ControlMessage> = _AbilityUsesView(uses: uses, onChange)
        abilityViews.append(abilityUses)
    }

    return Stack(
        .down,
        abilityViews.reduce([View<ControlMessage>]()) { views, abilityView in
            if views.isEmpty {
                return [abilityView]
            } else {
                return views + [Space().height(1), abilityView]
            }
        })
}

func _AbilityTitleView(_ title: String) -> View<ControlMessage> {
    Text(title.bold()).centered().underlined()
}
func _AbilityDescriptionView(_ description: String) -> View<ControlMessage> {
    Text(description, .wrap(true))
        .fitInContainer(dimension: .width)
}
func _AbilityUsesView(
    uses: Ability.Uses, _ onChange: @escaping (Int) -> ControlMessage
) -> View<ControlMessage> {
    Flow(
        .ltr,
        [
            (
                .fixed,
                OnLeftClick(
                    Text("[Use]".foreground(.green)), onChange(uses.amount))
            ),
            (.flex1, Space()),
            (.fixed, Text("\(uses.type.toReadable): \(uses.amount)")),
        ])
}
