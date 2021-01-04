////
///  ActionView.swift
//

import Ashen

func ActionView(
    _ action: Action, sheet: Sheet, onExpand: @escaping @autoclosure SimpleEvent<ControlMessage>,
    onChange: @escaping (Int) -> ControlMessage, onResetUses: @escaping @autoclosure SimpleEvent<ControlMessage>,
    onRoll: @escaping (Roll) -> ControlMessage
) -> View<ControlMessage> {
    let expandedViews: [View<ControlMessage>]
    let buttonText: String
    if action.isExpanded {
        let actionStats: View<ControlMessage>? = _ActionStatsView(
            action, sheet: sheet, onChange, onResetUses(), onRoll)
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

func _ActionStatsView(
    _ action: Action, sheet: Sheet, _ onChange: @escaping (Int) -> ControlMessage,
    _ onResetUses: @escaping @autoclosure SimpleEvent<ControlMessage>,
    _ onRoll: @escaping (Roll) -> ControlMessage
) -> View<ControlMessage>? {
    var actionViews = action.subactions.reduce([View<ControlMessage>]()) { views, sub in
        let statViews: [View<ControlMessage>] = [
            sub.check.map({ _ActionCheckView($0, sheet: sheet, onRoll) }) as View<ControlMessage>?,
            sub.damage.map({ _ActionDamageView($0, sheet: sheet, onRoll) }) as View<ControlMessage>?,
            sub.type.map({ _ActionTypeView($0, sheet: sheet, onRoll) }),
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
                                + statViews.flatMap { view -> [(FlowSize, View<ControlMessage>)] in
                                    [(.flex1, view), (.fixed, Space().width(1))]
                                }),
                    ])
            ]
        } else {
            return views + [
                Flow(
                    .ltr,
                    [(.fixed, Space().width(1))]
                        + statViews.flatMap { view -> [(FlowSize, View<ControlMessage>)] in
                            [(.flex1, view), (.fixed, Space().width(1))]
                        })
            ]
        }
    }

    if let description = action.description, !description.isEmpty {
        let actionDescription: View<ControlMessage> = _ActionDescriptionView(description)
        actionViews.append(actionDescription)
    }

    if let remainingUses = action.remainingUses {
        let actionUses: View<ControlMessage> = _ActionUsesView(
            action: action, remainingUses: remainingUses, sheet: sheet,
            onChange, onResetUses())
        actionViews.append(actionUses)
    }

    guard !actionViews.isEmpty else { return nil }
    return Stack(
        .down,
        actionViews.reduce([View<ControlMessage>]()) { views, actionView in
            if views.isEmpty {
                return [actionView]
            } else {
                return views + [Space().height(1), actionView]
            }
        })
}

func _ActionTitleView(_ title: String) -> View<ControlMessage> {
    Text(title.bold()).centered().underlined()
}
func _ActionLevelView(_ level: String?) -> View<ControlMessage> {
    level.map { Text($0) } ?? Space()
}
func _ActionCheckView(_ check: Operation, sheet: Sheet, _ onRoll: @escaping (Roll) -> ControlMessage)
    -> View<ControlMessage>
{
    StatView(title: "Check", value: check, sheet: sheet, onRoll: onRoll)
}
func _ActionDamageView(_ damage: Operation, sheet: Sheet, _ onRoll: @escaping (Roll) -> ControlMessage)
    -> View<ControlMessage>
{
    StatView(title: "Damage", value: damage, sheet: sheet, onRoll: onRoll)
}
func _ActionTypeView(_ type: String, sheet: Sheet, _ onRoll: @escaping (Roll) -> ControlMessage) -> View<ControlMessage> {
    StatView(title: "Type", value: .string(type), sheet: sheet, onRoll: onRoll)
}
func _ActionDescriptionView(_ description: String) -> View<ControlMessage> {
    Text(description, .wrap(true))
        .fitInContainer(dimension: .width)
}
func _ActionUsesView(
    action: Action, remainingUses: Int, sheet: Sheet,
    _ onChange: @escaping (Int) -> ControlMessage,
    _ onResetUses: @escaping @autoclosure SimpleEvent<ControlMessage>
) -> View<ControlMessage> {
    let remaining: View<ControlMessage>
    if let maxUses = action.maxUses {
        remaining = Text(" \(remainingUses) of \(maxUses.eval(sheet).toReadable) remaining")
    } else {
        remaining = Text(" \(remainingUses) remaining")
    }
    let canAdd: Bool
    if let maxUses = action.maxUses, let value = maxUses.eval(sheet).toInt {
        canAdd = remainingUses < value
    } else {
        canAdd = true
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
            (
                .fixed,
                canAdd
                    ? OnLeftClick(Text("[Add]".foreground(.green)), onChange(1))
                    : Text("[Add]".foreground(.black))
            ),
        ]
            + (action.maxUses != nil
                ? [
                    (.fixed, Space().width(1)),
                    (.fixed, OnLeftClick(Text("[Reset]".foreground(.blue)), onResetUses())),
                ] : []))
}
