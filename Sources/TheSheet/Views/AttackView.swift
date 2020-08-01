////
///  AttackView.swift
//

import Ashen

func AttackView<Msg>(_ attack: Attack) -> View<Msg> {
    let attackStats: View<Msg>? = _AttackViewStats(attack)
    let attackDescription: View<Msg>? = attack.description.map { _AttackViewDescription($0) }
    return Stack(
        .down,
        [
            Text(attack.title.bold()).centered().underlined()
        ] + (attackStats.map { [$0] } ?? []) + (attackDescription.map { [$0] } ?? []))
}

func _AttackViewStats<Msg>(_ attack: Attack) -> View<Msg>? {
    let stats: [View<Msg>] = [
        attack.check.map(_AttackViewCheck) as View<Msg>?,
        attack.damage.isEmpty ? nil : _AttackViewDamage(attack.damage),
        attack.damageType.map(_AttackViewType),
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

func _AttackViewCheck<Msg>(_ check: Formula) -> View<Msg> {
    StatView(Stat(title: "Check", value: check))
}
func _AttackViewDamage<Msg>(_ damage: [Roll]) -> View<Msg> {
    StatView(
        Stat(title: "Damage", value: .string(damage.map { $0.toReadable }.joined(separator: "+"))))
}
func _AttackViewType<Msg>(_ damageType: String) -> View<Msg> {
    StatView(Stat(title: "Type", value: .string(damageType)))
}
func _AttackViewDescription<Msg>(_ description: Attributed) -> View<Msg> {
    Text(description)
}
