////
///  ActionView.swift
//

import Ashen

func ActionView<Msg>(
    _ action: Action, onExpand: @escaping @autoclosure SimpleEvent<Msg>,
    onChange: @escaping (Int) -> Msg, onResetUses: @escaping @autoclosure SimpleEvent<Msg>
) -> View<
    Msg
> {
    let view: View<Msg>
    if action.isExpanded {
        let actionStats: View<Msg>? = _ActionViewStats(action, onChange, onResetUses())
        let expandedViews: [View<Msg>] = actionStats.map { [$0] } ?? []
        view = Stack(
            .down,
            [
                ZStack(
                    OnLeftClick(
                        Text("↑↑↑").bold().aligned(.topRight), onExpand()),
                    Text(action.title.bold()).centered().underlined(),
                    action.level.map { Text($0) } ?? Space()
                ).matchContainer(.width)
            ] + expandedViews)
    } else {
        view = Stack(
            .down,
            [
                ZStack(
                    OnLeftClick(
                        Text("↓↓↓").bold().aligned(.topRight), onExpand()),
                    Text(action.title.bold()).centered().underlined(),
                    action.level.map { Text($0) } ?? Space()
                ).matchContainer(.width)
            ])
    }
    return view.border(.single)
}

func _ActionViewStats<Msg>(
    _ action: Action, _ onChange: @escaping (Int) -> Msg,
    _ onResetUses: @escaping @autoclosure SimpleEvent<Msg>
) -> View<Msg>? {
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

    if let description = action.description, !description.attributedCharacters.isEmpty {
        let actionDescription: View<Msg> = _ActionViewDescription(description)
        actionViews.append(actionDescription)
    }

    if let remainingUses = action.remainingUses {
        let actionChanges: View<Msg> = _ActionViewUses(
            uses: action.uses, remainingUses: remainingUses, onChange, onResetUses())
        actionViews.append(actionChanges)
    }

    guard !actionViews.isEmpty else { return nil }
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
func _ActionViewDescription<Msg>(_ description: String) -> View<
    Msg
> {
    Text(description, .wrap(true))
        .fitInContainer(
            .width)
}
func _ActionViewUses<Msg>(
    uses: Int?, remainingUses: Int, _ onChange: @escaping (Int) -> Msg,
    _ onResetUses: @escaping @autoclosure SimpleEvent<Msg>
) -> View<Msg> {
    let remaining: View<Msg>
    if let uses = uses {
        remaining = Text(" \(remainingUses) of \(uses) remaining")
    } else {
        remaining = Text(" \(remainingUses) remaining")
    }
    return Flow(
        .ltr,
        [
            (
                .fixed,
                OnLeftClick(
                    Text("[Use]".foreground(remainingUses > 0 ? .green : .red)), onChange(-1))
            ),
            (.fixed, remaining),
            (.flex1, Space()),
            (.fixed, OnLeftClick(Text("+Add"), onChange(1))),
        ]
            + (uses != nil
                ? [
                    (.fixed, Space().width(1)),
                    (.fixed, OnLeftClick(Text("[Reset]"), onResetUses())),
                ] : []))
}
