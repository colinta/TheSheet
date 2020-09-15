////
///  HitDiceView.swift
//

import Ashen

func HitDiceView<Msg>(hitDice: [HitDice],
    sheet: Sheet,
    onUse: @escaping (Int, Roll) -> Msg
) -> View<Msg>
{
    Stack(
        .down,
        [
            Text("Hit Dice").bold().centered().underlined(),
            Flow(
                .ltr,
                [(.fixed, Space().width(1))] + hitDice.enumerated().flatMap { index, hitDie -> [(FlowSize, View<Msg>)] in
                    let modifier = hitDie.modifier.eval(sheet).toInt ?? 0
                    let roll = Roll(dice: [Dice(n: 1, d: hitDie.d)], modifier: modifier)
                    let valueView: View<Msg> = OnLeftClick(Text("\(hitDie.remaining)").centered().underlined(), onUse(index, roll))
                    let titleView: View<Msg> = Text("1d\(hitDie.d)").centered()
                    return [(.flex1, Stack(.down,
                        [
                            valueView,
                            titleView,
                        ])), (.fixed, Space().width(1))]
                    }
            )
        ]
    )
}
