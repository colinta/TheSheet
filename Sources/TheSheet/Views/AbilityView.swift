////
///  AbilityView.swift
//

import Ashen

func AbilityView<Msg>(
    _ ability: Ability, onExpand: @escaping @autoclosure SimpleEvent<Msg>,
    onChange: @escaping (Int) -> Msg
) -> View<
    Msg
> {
    let expandedViews: [View<Msg>]
    let buttonText: String
    if ability.isExpanded {
        let abilityStats: View<Msg>? = _AbilityDescriptionView(
            ability, onChange)
        expandedViews = abilityStats.map { [$0] } ?? []
        buttonText = "↑↑↑"
    } else {
        buttonText = "↓↓↓"
        expandedViews = []
    }
    return Stack(
        .down,
        [
            ZStack(
                _AbilityTitleView(ability.title),
                OnLeftClick(
                    Text(buttonText).bold().aligned(.topRight), onExpand())
            ).matchContainer(.width)
        ] + expandedViews
    ).border(.single)
}

func _AbilityDescriptionView<Msg>(
    _ ability: Ability, _ onChange: @escaping (Int) -> Msg
) -> View<Msg>? {
    var abilityViews: [View<Msg>] = [_AbilityDescriptionView(ability.description)]

    if let uses = ability.uses {
        let abilityUses: View<Msg> = _AbilityUsesView(uses: uses, onChange)
        abilityViews.append(abilityUses)
    }

    return Stack(
        .down,
        abilityViews.reduce([View<Msg>]()) { views, abilityView in
            if views.isEmpty {
                return [abilityView]
            } else {
                return views + [Space().height(1), abilityView]
            }
        })
}

func _AbilityTitleView<Msg>(_ title: String) -> View<Msg> {
    Text(title.bold()).centered().underlined()
}
func _AbilityDescriptionView<Msg>(_ description: String) -> View<
    Msg
> {
    Text(description, .wrap(true))
        .fitInContainer(.width)
}
func _AbilityUsesView<Msg>(
    uses: Ability.Uses, _ onChange: @escaping (Int) -> Msg
) -> View<Msg> {
    Flow(
        .ltr,
        [
            (.fixed, OnLeftClick(
                Text("[Use]".foreground(.green)), onChange(uses.amount))),
            (.flex1, Space()),
            (.fixed, Text("\(uses.type.toReadable): \(uses.amount)")),
        ])
}
