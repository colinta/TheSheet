////
///  FormulasView.swift
//

import Ashen

func FormulasView<Msg>(_ formulas: [(String, Formula)]) -> View<Msg> {
    Stack(
        .down,
        formulas.map { name, formula in
            FormulaView(name, formula)
        })
}

func FormulaView<Msg>(_ name: String, _ formula: Formula) -> View<Msg> {
    Stack(
        .ltr,
        [
            Text(name.underlined()),
            Text(" = "),
            Text(formula.toEditable),
        ])
}
