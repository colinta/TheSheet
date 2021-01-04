////
///  JournalView.swift
//

import Ashen

func JournalView(journal: Journal, onExpand: @escaping @autoclosure SimpleEvent<ControlMessage>) -> View<ControlMessage> {
    let expandedViews: [View<ControlMessage>]
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
