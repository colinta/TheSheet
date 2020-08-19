////
///  PointsEditor.swift
//

import Ashen
import Foundation

func PointsEditor(_ points: Points, editor: AtXYEditor) -> View<EditableControl.Message> {
    // type: PointType
    // case level
    // case hitPoints
    // case sorcery
    // case ki
    // case other(String, String)
    // case many([PointType])
    // shouldResetOnLongRest: Bool

    let isEditingTitle = editor.atXY?.x == 0
    let titleEditor = OnLeftClick(
        Input(
            points.title, onChange: { EditableControl.Message.changeString(.title, $0) },
            .isResponder(isEditingTitle)),
        EditableControl.Message.firstResponder(IndexPath(indexes: [0, 0])),
        .highlight(false)
    )
    let maxEnabled = points.max != nil
    return Stack(
        .down,
        [
            Flow(
                .ltr,
                [
                    (.fixed, Text("Title: ")),
                    (.flex1, titleEditor),
                ]),
            Flow(
                .ltr,
                [
                    (.fixed, Text("Current:")),
                    (.flex1, Space()),
                    (
                        .fixed,
                        PlusMinus(
                            points.current, { EditableControl.Message.changeInt(.current, $0) })
                    ),
                ]),
            Flow(
                .ltr,
                [
                    (
                        .fixed,
                        OnLeftClick(
                            Text(maxEnabled ? "[◼]" : "[ ]"),
                            EditableControl.Message.changeBool(.max, !maxEnabled))
                    ),
                    (.fixed, Text(" Max:".foreground(maxEnabled ? .none : .black))),
                    (.flex1, Space()),
                    (
                        .fixed,
                        PlusMinus(
                            points.max, { EditableControl.Message.changeInt(.max, $0) },
                            .isEnabled(maxEnabled))
                    ),
                ]),
            Flow(
                .ltr,
                [
                    (
                        .fixed,
                        OnLeftClick(
                            Text(maxEnabled && points.shouldResetOnLongRest ? "[◼]" : "[ ]")
                                .foreground(color: maxEnabled ? .none : .black),
                            EditableControl.Message.changeBool(
                                .resets, !points.shouldResetOnLongRest), .isEnabled(maxEnabled)
                        )
                    ),
                    (.fixed, Text(" Resets on Long Rest".foreground(maxEnabled ? .none : .black))),
                ]),
            Stack(
                .down,
                [
                    Text("Point Types:".underlined())
                ]
                    + Points.PointType.all(points.types).map { (index, pointType) in
                        let titlePath = 1
                        let variablePath = 2
                        let isEditingTitle = editor.atXY?.x == titlePath && editor.atXY?.y == index
                        let isEditingVariable =
                            editor.atXY?.x == variablePath && editor.atXY?.y == index
                        let selector: View<EditableControl.Message>
                        if !pointType.isBuiltIn {
                            selector = Text("[x] ".foreground(.red))
                        } else if points.is(pointType) {
                            selector = Text("[◼] ")
                        } else {
                            selector = Text("[ ] ")
                        }
                        return Stack(
                            .ltr,
                            [
                                OnLeftClick(
                                    selector, EditableControl.Message.togglePointType(pointType)),
                                pointType.isBuiltIn
                                    ? Text(pointType.toReadable)
                                    : OnLeftClick(
                                        Input(
                                            pointType.toReadable,
                                            onChange: {
                                                value in
                                                EditableControl.Message.atIndex(
                                                    index, .changeString(.title, value))
                                            },
                                            .isResponder(isEditingTitle),
                                            .placeholder("Title")),
                                        EditableControl.Message.firstResponder(
                                            IndexPath(indexes: [titlePath, index]))
                                    ).minWidth(4),
                                Text(" ("),
                                pointType.isBuiltIn
                                    ? Text(pointType.toVariable.underlined().foreground(.green))
                                    : OnLeftClick(
                                        Input(
                                            pointType.toVariable,
                                            onChange: {
                                                value in
                                                EditableControl.Message.atIndex(
                                                    index, .changeString(.variable, value))
                                            },

                                            .isResponder(isEditingVariable),
                                            .placeholder("variable")),
                                        EditableControl.Message.firstResponder(
                                            IndexPath(indexes: [variablePath, index]))
                                    ).minWidth(4),
                                Text(")"),
                            ])
                    } + [
                        OnLeftClick(Text("[+]"), EditableControl.Message.add)
                    ]),
        ])
}
