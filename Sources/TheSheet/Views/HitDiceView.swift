////
///  HitDiceView.swift
//

import Ashen

func HitDiceView(hitDice: [HitDice],
    sheet: Sheet,
    onUse: @escaping (Int, Roll) -> ControlMessage,
    onChange: @escaping (Int, Int) -> ControlMessage
) -> View<ControlMessage>
{
    Stack(
        .down,
        [
            Text("Hit Dice").bold().centered().underlined(),
            Flow(
                .ltr,
                [(.fixed, Space().width(1))] + hitDice.enumerated().flatMap { index, hitDie -> [(FlowSize, View<ControlMessage>)] in
                    let modifier = hitDie.modifier.eval(sheet).toInt ?? 0
                    let roll = Roll(dice: [Dice(n: 1, d: hitDie.d)], modifier: modifier)
                    let valueView: View<ControlMessage> = OnLeftClick(Text("\(hitDie.remaining)").centered(), onUse(index, roll))
                    let subtractView: View<ControlMessage> = OnLeftClick(Text("[-]".foreground(.red)), onChange(index, -1))
                    let addView: View<ControlMessage> = OnLeftClick(Text("[+]".foreground(.green)), onChange(index, 1))
                    let titleView: View<ControlMessage> = Text("1d\(hitDie.d)").centered()
                    return [(.flex1, Stack(.down,
                        [
                            ZStack([
                                valueView.aligned(.middleCenter),
                                Stack(.ltr, [subtractView, addView]).aligned(.middleRight)]).styled(.underline),
                            titleView,
                        ])), (.fixed, Space().width(1))]
                    }
            )
        ]
    )
}
