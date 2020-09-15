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
    let buttonView: View<Msg>
    let abilityStats: View<Msg>? = _AbilityDescriptionView(
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
        .fitInContainer(dimension: .width)
}
func _AbilityUsesView<Msg>(
    uses: Ability.Uses, _ onChange: @escaping (Int) -> Msg
) -> View<Msg> {
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
