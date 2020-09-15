////
///  TakeRestView.swift
//

import Ashen

func TakeRestView<Msg>(
    _ onRest: @escaping @autoclosure SimpleEvent<Msg>
) -> View<Msg> {
    OnLeftClick(Text("Take a Long Rest".bold()).centered(), onRest()).border(.single)
}
