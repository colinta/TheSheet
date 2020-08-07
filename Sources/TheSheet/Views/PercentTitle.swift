////
///  PercentTitle.swift
//

import Ashen

func PercentTitle<Msg>(_ title: Attributed, _ current: Int, _ max: Int?) -> View<Msg> {
    let percent: Float
    if let max = max, max > 0 {
        percent = Float(current) / Float(max)
    } else {
        percent = current == 0 ? 0 : 1
    }
    return Text(title).centered().modifyCharacters { pt, size, c in
        if Float(pt.x) < Float(size.width) * percent {
            return c.styled(.background(.green))
        } else {
            return c.styled(.background(.blue))
        }
    }
}
