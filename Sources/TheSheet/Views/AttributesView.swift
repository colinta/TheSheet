////
///  AttributesView.swift
//

import Ashen

func AttributesView<Msg>(_ attributes: [Attribute]) -> View<Msg> {
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
    return Flow(
        .ltr,
        [
            (.fixed, Repeating(Text(" ")).width(1)),
            (.flex1, Stack(.down, lhs.map { AttributeView($0) })),
            (.fixed, Repeating(Text("│ ")).width(2)),
            (.flex1, Stack(.down, rhs.map { AttributeView($0) })),
        ])
}

func AttributeView<Msg>(_ attribute: Attribute) -> View<Msg> {
    Stack(
        .ltr,
        [
            Stack(
                .down,
                [
                    Text(attribute.title.bold().underlined()),
                    Stack(
                        .ltr,
                        [
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
                                    Text(attribute.save.toModString).centered().underlined(),
                                    Text("Save"),
                                ]),
                        ]),
                ])
        ]
    ).height(4)
}
