////
///  AttributesView.swift
//

import Ashen

func AttributesView<Msg>(_ attributes: [Attribute], onChange: @escaping (Int, Int) -> Msg) -> View<
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
        AttributeView(attr, onChange: { delta in onChange(attrIndex, delta) })
    }
    let rhsViews = rhs.enumerated().map { attrIndex, attr in
        AttributeView(attr, onChange: { delta in onChange(lhs.count + attrIndex, delta) })
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

func AttributeView<Msg>(_ attribute: Attribute, onChange: @escaping (Int) -> Msg) -> View<Msg> {
    Stack(
        .ltr,
        [
            Stack(
                .down,
                [
                    Text(attribute.title.bold().underlined()).centered(),
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
                                    Text("\(attribute.score)").centered().underlined(),
                                    Text("Score"),
                                ]),
                            Space().width(1),
                            Stack(
                                .down,
                                [
                                    Text(attribute.modifier.toModString).centered().underlined(),
                                    Text("Modifier"),
                                ]),
                            Space().width(1),
                            Stack(
                                .down,
                                [
                                    Text(attribute.save(proficiency: 2).toModString).centered()
                                        .underlined(),
                                    Text("Save"),
                                ]),
                        ]),
                ])
        ]
    ).height(4)
}
