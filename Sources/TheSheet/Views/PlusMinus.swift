////
///  PlusMinus.swift
//

import Ashen

enum PlusMinusOption {
    case noMin
    case noMax
    case min(Int)
    case max(Int)
    case isEnabled(Bool)
}

func PlusMinus<Msg>(
    _ current: Int?, _ onChange: @escaping (Int) -> Msg, _ options: PlusMinusOption...
) -> View<Msg> {
    var minVal: Int? = 0
    var maxVal: Int?
    var isEnabled = true
    for opt in options {
        switch opt {
        case .noMin:
            minVal = nil
        case .noMax:
            maxVal = nil
        case let .min(val):
            minVal = val
        case let .max(val):
            maxVal = val
        case let .isEnabled(isEnabledOpt):
            isEnabled = isEnabledOpt
        }
    }

    return Stack(
        .ltr,
        [
            Text("\(current?.description ?? "") ").aligned(.topRight),
            OnClick(
                Text("[-]".foreground(isEnabled ? .red : .black)),
                { button in
                    let amount: Int
                    if button == .left {
                        amount = 1
                    } else {
                        amount = 5
                    }
                    let value = (current ?? 0) - amount
                    if let minVal = minVal {
                        return onChange(max(minVal, value))
                    }
                    return onChange(value)
                }, .isEnabled(isEnabled)),
            OnClick(
                Text("[+]".foreground(isEnabled ? .green : .black)),
                { button in
                    let amount: Int
                    if button == .left {
                        amount = 1
                    } else {
                        amount = 5
                    }
                    let value = (current ?? 0) + amount
                    if let maxVal = maxVal {
                        return onChange(min(maxVal, value))
                    }
                    return onChange(value)
                }, .isEnabled(isEnabled)),
        ])
}
