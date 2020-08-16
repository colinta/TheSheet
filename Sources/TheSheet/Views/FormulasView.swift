////
///  FormulasView.swift
//

import Ashen

func FormulasView<Msg>(editable: [Formula], fixed: [Formula], sheet: Sheet) -> View<Msg> {
    Stack(
        .down,
        editable.map { formula in
            FormulaView(formula, sheet: sheet, isEditable: true)
        }
            + [
                Repeating(Text("─".foreground(.black))).height(1),
                Text(" Variables ".bold().underlined()).centered(),
            ]
            + fixed.map { formula in
                FormulaView(formula, sheet: sheet, isEditable: false)
            }
            + [
                Repeating(Text("─".foreground(.black))).height(1),
                Text(" Notes ".bold().underlined()).centered(),
                Text("Modifiers are colored in "
                    + "bright blue.\n".foreground(.blue).bold()
                    + "They have a prefix of "
                    + "+N".foreground(.blue).bold()
                    + " or "
                    + "--N".foreground(.blue).bold(), .wrap(true))
            ]
    )
}

func FormulaView<Msg>(_ formula: Formula, sheet: Sheet, isEditable: Bool) -> View<Msg> {
    Stack(
        .ltr,
        [
            Text(formula.variable.underlined()),
            Text(" = "),
            Text(formula.operation.toAttributed(sheet)),
        ])
}
