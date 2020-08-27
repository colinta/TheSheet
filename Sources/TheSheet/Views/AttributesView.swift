////
///  AttributesView.swift
//

import Ashen

func AttributesView<Msg>(_ attributes: [Attribute], sheet: Sheet, onChange: @escaping (Int, Int) -> Msg) -> View<
    Msg
> {
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
        AttributeView(attr, sheet: sheet, onChange: { delta in onChange(attrIndex, delta) })
    }
    let rhsViews = rhs.enumerated().map { attrIndex, attr in
        AttributeView(attr, sheet: sheet, onChange: { delta in onChange(lhs.count + attrIndex, delta) })
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

func AttributeView<Msg>(_ attribute: Attribute, sheet: Sheet, onChange: @escaping (Int) -> Msg) -> View<Msg> {
    Stack(
        .ltr,
        [
            Stack(
                .down,
                [
                    Text(((attribute.isProficient ? "◼ " : "") + attribute.title).bold()).centered(),
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

                            Stack(
                                .down,
                                [
                                    Text(Operation.Value.integer(attribute.score).toAttributed).centered().underlined(),
                                    Text("Score"),
                                ]),
                            Space().width(1),
                            Stack(
                                .down,
                                [
                                    Text(attribute.modifier.toAttributed).centered().underlined(),
                                    Text("Modifier"),
                                ]),
                            Space().width(1),
                            Stack(
                                .down,
                                [
                                    Text(attribute.save(sheet).toAttributed).centered()
                                        .underlined(),
                                    Text("Save"),
                                ]),
                        ]),
                ])
        ]
    ).height(4)
}
