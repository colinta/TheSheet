////
///  JournalView.swift
//

import Ashen

func JournalView<Msg>(journal: Journal, onExpand: @escaping @autoclosure SimpleEvent<Msg>) -> View<
    Msg
> {
    let expandedViews: [View<Msg>]
    let buttonText: String
    if journal.isExpanded {
        expandedViews = [Text(journal.text, .wrap(true))]
        buttonText = "↑↑↑"
    } else {
        buttonText = "↓↓↓"
        expandedViews = []
    }

    return Stack(
        .down,
        [
            ZStack(
                Text(journal.title.bold(), .wrap(true)).centered(),
                OnLeftClick(
                    Text(buttonText).bold().aligned(.topRight), onExpand())
            ).matchContainer(dimension: .width),
            Repeating(Text("-".foreground(.black))).height(1),
        ] + expandedViews)
}
