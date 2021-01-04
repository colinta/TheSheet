////
///  AttributesView.swift
//

import Ashen

func AttributesView(
    _ attributes: [Attribute], sheet: Sheet, onChange: @escaping (Int, Int) -> ControlMessage,
    onRoll: @escaping (Roll) -> ControlMessage
) -> View<ControlMessage> {
    let (lhs, rhs) = attributes.enumerated().reduce(([Attribute](), [Attribute]())) {
        lhs_rhs, index_attr in
        let (lhs, rhs) = lhs_rhs
        let (index, attr) = index_attr
        if index < attributes.count / 2 {
            return (lhs + [attr], rhs)
        } else {
            return (lhs, rhs + [attr])
        }
    }
    let lhsViews = lhs.enumerated().map { attrIndex, attr in
        AttributeView(
            attr, sheet: sheet, onChange: { delta in onChange(attrIndex, delta) },
            onRoll: onRoll
        )
    }
    let rhsViews = rhs.enumerated().map { attrIndex, attr in
        AttributeView(
            attr, sheet: sheet, onChange: { delta in onChange(lhs.count + attrIndex, delta) },
            onRoll: onRoll
        )
    }
    return Flow(
        .ltr,
        [
            (.fixed, Space().width(1)),
            (.flex1, Stack(.down, lhsViews).centered()),
            (.fixed, Repeating(Text("│ ")).width(2)),
            (.flex1, Stack(.down, rhsViews).centered()),
        ])
}

func AttributeView(
    _ attribute: Attribute, sheet: Sheet, onChange: @escaping (Int) -> ControlMessage,
    onRoll: @escaping (Roll) -> ControlMessage
)
    -> View<ControlMessage>
{
    Stack(
        .ltr,
        [
            Stack(
                .down,
                [
                    Text(((attribute.isProficient ? "◼ " : "") + attribute.title).bold())
                        .centered(),
                    Stack(
                        .ltr,
                        [
                            Stack(
                                .down,
                                [
                                    OnLeftClick(Text("[+]".foreground(.green)), onChange(1))
                                        .aligned(.middleLeft),
                                    OnLeftClick(Text("[-]".foreground(.red)), onChange(-1)).aligned(
                                        .middleLeft),
                                ]),

                            StatView(
                                title: "Score", value: .integer(attribute.score),
                                sheet: sheet, onRoll: onRoll),
                            Space().width(1),
                            StatView(
                                title: "Modifier", value: attribute.modifier, sheet: sheet,
                                onRoll: onRoll),
                            Space().width(1),
                            StatView(
                                title: "Save", value: attribute.save, sheet: sheet,
                                onRoll: onRoll),
                        ]),
                ])
        ]
    ).height(4)
}
