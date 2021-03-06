////
///  PercentTitle.swift
//

import Ashen

func PercentTitle<Msg>(_ current: Int, _ maxValue: Int?) -> View<Msg> {
    let maxPercent: Float
    let currentPercent: Float
    if let maxValue = maxValue, maxValue > 0 {
        maxPercent = Float(maxValue) / Float(max(maxValue, current))
        currentPercent = Float(current) / Float(maxValue)
    } else {
        maxPercent = current == 0 ? 0 : 1
        currentPercent = maxPercent
    }
    return Space().height(1).centered().modifyCharacters { pt, size, c in
        if Float(pt.x) > Float(size.width) * maxPercent, maxValue ?? 0 == 0 {
            return c.styled(.background(.yellow))
        } else if Float(pt.x) > Float(size.width) * maxPercent {
            return c.styled(.background(.brightGreen))
        } else if Float(pt.x) < Float(size.width) * currentPercent {
            return c.styled(.background(.green))
        } else {
            return c.styled(.background(.blue))
        }
    }
}
