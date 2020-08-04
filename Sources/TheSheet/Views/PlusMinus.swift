////
///  PlusMinus.swift
//

import Ashen

enum PlusMinusOption {
    case min(Int)
    case max(Int)
}

func PlusMinus<Msg>(
    _ current: Int, _ onChange: @escaping (Int) -> Msg, _ options: PlusMinusOption...
) -> View<Msg> {
    var minVal: Int?
    var maxVal: Int?
    for opt in options {
        switch opt {
        case let .min(val):
            minVal = val
        case let .max(val):
            maxVal = val
        }
    }

    return Flow(
        .ltr,
        [
            (.flex1, Text("\(current) ").aligned(.topRight)),
            (
                .fixed,
                OnClick(
                    Text("[-]".bold().foreground(.red)),
                    { button in
                        let amount: Int
                        if button == .left {
                            amount = 1
                        } else {
                            amount = 5
                        }
                        if let minVal = minVal {
                            return onChange(max(minVal, current - amount))
                        }
                        return onChange(current - amount)
                    })
            ),
            (
                .fixed,
                OnClick(
                    Text("[+]".bold().foreground(.green)),
                    { button in
                        let amount: Int
                        if button == .left {
                            amount = 1
                        } else {
                            amount = 5
                        }
                        if let maxVal = maxVal {
                            return onChange(min(maxVal, current - amount))
                        }
                        return onChange(current + amount)
                    })
            ),
        ])
}
