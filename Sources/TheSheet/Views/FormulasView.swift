////
///  FormulasView.swift
//

import Ashen

func FormulasView(editable: [Formula], fixed: [Formula], sheet: Sheet) -> View<ControlMessage> {
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

func FormulaView(_ formula: Formula, sheet: Sheet, canEdit: Bool) -> View<ControlMessage> {
    let formulaView: View<ControlMessage> = Stack(
        .ltr,
        [
            Text(formula.variable.underlined()),
            Text(" = "),
            Text(formula.operation.toAttributed(sheet), .wrap(true)),
        ])
    if canEdit {
        return Stack(
            .down,
            [
                formulaView,
                Stack(
                    .ltr,
                    [
                        Text(String(repeating: " ", count: formula.variable.count)),
                        Text("-> ".bold()),
                        Text(formula.operation.eval(sheet).toAttributed),
                    ]),
            ])
    } else {
        return formulaView
    }
}
