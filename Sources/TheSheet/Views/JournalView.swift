////
///  JournalView.swift
//

import Ashen

func JournalView<Msg>(journal: (String, String)) -> View<Msg> {
    Stack(.down, [
        Text(journal.0.bold(), .wrap(true)).centered(),
        Repeating(Text("-".foreground(.black))).height(1),
        Text(journal.1, .wrap(true)).maxHeight(10),
        journal.1.lines.count > 10 ? Text("…") : Space(),
    ])
}
