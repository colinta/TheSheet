////
///  PercentTitle.swift
//

import Ashen

func PercentTitle<Msg>(_ title: Attributed, _ current: Int, _ max: Int) -> View<Msg> {
    let percent: Float
    if max == 0 {
        percent = 0
    } else {
        percent = Float(current) / Float(max)
    }
    return Text(title).centered().modifyCharacters { pt, size, c in
        if Float(pt.x) < Float(size.width) * percent {
            return c.styled(.background(.green))
        } else {
            return c.styled(.background(.blue))
        }
    }
}
