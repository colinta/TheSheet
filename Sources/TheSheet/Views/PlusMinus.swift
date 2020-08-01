////
///  PlusMinus.swift
//

import Ashen

func PlusMinus<Msg>(_ current: Int, _ onChange: @escaping (Int) -> Msg) -> View<Msg> {
    Flow(
        .ltr,
        [
            (.flex1, Text("\(current) ").aligned(.topRight)),
            (
                .fixed,
                OnClick(
                    Text("[-]".bold().foreground(.red)),
                    { mouseEvent in
                        let amount: Int
                        if mouseEvent.button == .left {
                            amount = 1
                        } else {
                            amount = 5
                        }
                        return onChange(current - amount)
                    })
            ),
            (
                .fixed,
                OnClick(
                    Text("[+]".bold().foreground(.green)),
                    { mouseEvent in
                        let amount: Int
                        if mouseEvent.button == .left {
                            amount = 1
                        } else {
                            amount = 5
                        }
                        return onChange(current + amount)
                    })
            ),
        ])
}
