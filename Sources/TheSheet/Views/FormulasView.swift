////
///  FormulasView.swift
//

import Ashen

func FormulasView<Msg>(editable: [Formula], fixed: [Formula], sheet: Sheet) -> View<Msg> {
    Stack(
        .down,
        editable.map { formula in
            FormulaView(formula, sheet: sheet, canEdit: true)
        }
            + [
                Repeating(Text("─".foreground(.black))).height(1),
                Text(" Variables ".bold().underlined()).centered(),
            ]
            + fixed.map { formula in
                FormulaView(formula, sheet: sheet, canEdit: false)
            }
    )
}

func FormulaView<Msg>(_ formula: Formula, sheet: Sheet, canEdit: Bool) -> View<Msg> {
    Stack(
        .ltr,
        [
            Text(formula.variable.underlined()),
            Text(" = "),
            Text(
                [
                    formula.operation.toAttributed(sheet),
                    " -> ".bold(),
                    formula.operation.eval(sheet).toAttributed,
                ], .wrap(true)),
        ])
}
