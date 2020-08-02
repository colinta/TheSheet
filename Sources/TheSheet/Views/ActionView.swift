////
///  ActionView.swift
//

import Ashen

func ActionView<Msg>(_ action: Action) -> View<Msg> {
    let actionStats: View<Msg>? = _ActionViewStats(action)
    let actionDescription: View<Msg>? = action.description.map { _ActionViewDescription($0) }
    return Stack(
        .down,
        [
            Text(action.title.bold()).centered().underlined()
        ] + (actionStats.map { [$0] } ?? []) + (actionDescription.map { [$0] } ?? []))
}

func _ActionViewStats<Msg>(_ action: Action) -> View<Msg>? {
    let stats: [View<Msg>] = [
        action.check.map(_ActionViewCheck) as View<Msg>?,
        action.damage.isEmpty ? nil : _ActionViewDamage(action.damage),
        action.damageType.map(_ActionViewType),
    ].compactMap { $0 }

    if stats.isEmpty {
        return nil
    } else {
        return Flow(
            .ltr,
            [(.fixed, Space().width(1))]
                + stats.flatMap { view -> [(FlowSize, View<Msg>)] in
                    [(.flex1, view), (.fixed, Space().width(1))]
                })
    }
}

func _ActionViewCheck<Msg>(_ check: Formula) -> View<Msg> {
    StatView(Stat(title: "Check", value: check))
}
func _ActionViewDamage<Msg>(_ damage: [Roll]) -> View<Msg> {
    StatView(
        Stat(title: "Damage", value: .string(damage.map { $0.toReadable }.joined(separator: "+"))))
}
func _ActionViewType<Msg>(_ damageType: String) -> View<Msg> {
    StatView(Stat(title: "Type", value: .string(damageType)))
}
func _ActionViewDescription<Msg>(_ description: Attributed) -> View<Msg> {
    Text(description, .wrap(true))
}
