////
///  ActionView.swift
//

import Ashen

func ActionView<Msg>(
    _ action: Action, sheet: Sheet, onExpand: @escaping @autoclosure SimpleEvent<Msg>,
    onChange: @escaping (Int) -> Msg, onResetUses: @escaping @autoclosure SimpleEvent<Msg>
) -> View<
    Msg
> {
    let expandedViews: [View<Msg>]
    let buttonText: String
    if action.isExpanded {
        let actionStats: View<Msg>? = _ActionStatsView(
            action, sheet: sheet, onChange, onResetUses())
        expandedViews = actionStats.map { [$0] } ?? []
        buttonText = "↑↑↑"
    } else {
        buttonText = "↓↓↓"
        expandedViews = []
    }
    return Stack(
        .down,
        [
            ZStack(
                _ActionLevelView(action.level),
                _ActionTitleView(action.title),
                OnLeftClick(
                    Text(buttonText).bold().aligned(.topRight), onExpand())
            ).matchContainer(dimension: .width)
        ] + expandedViews
    ).border(.single)
}

func _ActionStatsView<Msg>(
    _ action: Action, sheet: Sheet, _ onChange: @escaping (Int) -> Msg,
    _ onResetUses: @escaping @autoclosure SimpleEvent<Msg>
) -> View<Msg>? {
    var actionViews = action.subactions.reduce([View<Msg>]()) { views, sub in
        let statViews: [View<Msg>] = [
            sub.check.map({ _ActionCheckView($0, sheet: sheet) }) as View<Msg>?,
            sub.damage.map({ _ActionDamageView($0, sheet: sheet) }) as View<Msg>?,
            sub.type.map({ _ActionTypeView($0, sheet: sheet) }),
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

    if let description = action.description, !description.isEmpty {
        let actionDescription: View<Msg> = _ActionDescriptionView(description)
        actionViews.append(actionDescription)
    }

    if let remainingUses = action.remainingUses {
        let actionUses: View<Msg> = _ActionUsesView(
            action: action, remainingUses: remainingUses, onChange, onResetUses())
        actionViews.append(actionUses)
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

func _ActionTitleView<Msg>(_ title: String) -> View<Msg> {
    Text(title.bold()).centered().underlined()
}
func _ActionLevelView<Msg>(_ level: String?) -> View<Msg> {
    level.map { Text($0) } ?? Space()
}
func _ActionCheckView<Msg>(_ check: Operation, sheet: Sheet) -> View<Msg> {
    StatView(Stat(title: "Check", value: check), sheet: sheet)
}
func _ActionDamageView<Msg>(_ damage: Operation, sheet: Sheet) -> View<Msg> {
    StatView(Stat(title: "Damage", value: damage), sheet: sheet)
}
func _ActionTypeView<Msg>(_ type: String, sheet: Sheet) -> View<Msg> {
    StatView(Stat(title: "Type", value: .string(type)), sheet: sheet)
}
func _ActionDescriptionView<Msg>(_ description: String) -> View<
    Msg
> {
    Text(description, .wrap(true))
        .fitInContainer(dimension: .width)
}
func _ActionUsesView<Msg>(
    action: Action, remainingUses: Int, _ onChange: @escaping (Int) -> Msg,
    _ onResetUses: @escaping @autoclosure SimpleEvent<Msg>
) -> View<Msg> {
    let remaining: View<Msg>
    if let uses = action.uses {
        remaining = Text(" \(remainingUses) of \(uses) remaining")
    } else {
        remaining = Text(" \(remainingUses) remaining")
    }
    let canAdd: Bool = action.maxUses.map { remainingUses < $0 } ?? true
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
            (
                .fixed,
                canAdd
                    ? OnLeftClick(Text("+Add".foreground(.green)), onChange(1))
                    : Text("+Add".foreground(.black))
            ),
        ]
            + (action.uses != nil
                ? [
                    (.fixed, Space().width(1)),
                    (.fixed, OnLeftClick(Text("[Reset]".foreground(.blue)), onResetUses())),
                ] : []))
}
