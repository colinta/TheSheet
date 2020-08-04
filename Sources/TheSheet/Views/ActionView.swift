////
///  ActionView.swift
//

import Ashen

func ActionView<Msg>(_ action: Action, _ onExpand: @escaping @autoclosure () -> Msg) -> View<Msg> {
    let view: View<Msg>
    if action.isExpanded {
        let actionStats: View<Msg>? = _ActionViewStats(action)
        let actionViews: [View<Msg>] = actionStats.map { [$0] } ?? []
        view = Stack(
            .down,
            [
                ZStack(
                    OnLeftClick(
                        Text("↑↑↑").bold().aligned(.topRight), onExpand()),
                    Text(action.title.bold()).centered().underlined(),
                    action.level.map { Text($0) } ?? Space()
                ).stretch(.horizontal)
            ] + actionViews)
    } else {
        view = Stack(
            .down,
            [
                ZStack(
                    OnLeftClick(
                        Text("↓↓↓").bold().aligned(.topRight), onExpand()),
                    Text(action.title.bold()).centered().underlined(),
                    action.level.map { Text($0) } ?? Space()
                ).stretch(.horizontal)
            ])
    }
    return view.border(.single)
}

func _ActionViewStats<Msg>(_ action: Action) -> View<Msg>? {
    var actionViews = action.subactions.reduce([View<Msg>]()) { views, sub in
        let statViews: [View<Msg>] = [
            sub.check.map(_ActionViewCheck) as View<Msg>?,
            sub.damage.isEmpty ? nil : _ActionViewDamage(sub.damage),
            sub.type.map(_ActionViewType),
        ].compactMap { $0 }

        if statViews.isEmpty {
            return views
        } else if let title = sub.title {
            return views + [
                Stack(
                    .down,
                    [
                        Text("\(title):"),
                        Flow(
                            .ltr,
                            [(.fixed, Space().width(1))]
                                + statViews.flatMap { view -> [(FlowSize, View<Msg>)] in
                                    [(.flex1, view), (.fixed, Space().width(1))]
                                }),
                    ])
            ]
        } else {
            return views + [
                Flow(
                    .ltr,
                    [(.fixed, Space().width(1))]
                        + statViews.flatMap { view -> [(FlowSize, View<Msg>)] in
                            [(.flex1, view), (.fixed, Space().width(1))]
                        })
            ]
        }
    }

    if let actionDescription: View<Msg> = action.description.map({ _ActionViewDescription($0) }) {
        actionViews.append(actionDescription)
    }

    if actionViews.isEmpty {
        return nil
    } else {
        return Stack(
            .down,
            actionViews.reduce([View<Msg>]()) { views, actionView in
                if views.isEmpty {
                    return [actionView]
                } else {
                    return views + [Space().height(1), actionView]
                }
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
func _ActionViewType<Msg>(_ type: String) -> View<Msg> {
    StatView(Stat(title: "Type", value: .string(type)))
}
func _ActionViewDescription<Msg>(_ description: Attributed) -> View<Msg> {
    Text(description, .wrap(true))
}
