////
///  Model.swift
//

import Ashen
import Foundation

let STATUS_TIMEOUT: TimeInterval = 3

struct Model {
    typealias Status = (msg: String, timeout: TimeInterval)

    let sheet: Sheet
    let undoSheets: [Sheet]
    let fileURL: URL?
    let changeColumn: Int?
    let scrollOffset: Int
    let columnScrollMaxOffsets: [Int: Int]
    let status: Status?

    var canUndo: Bool { !undoSheets.isEmpty }

    init(
        sheet: Sheet, undoSheets: [Sheet] = [], fileURL: URL? = nil, changeColumn: Int? = nil,
        scrollOffset: Int = 0,
        columnScrollMaxOffsets: [Int: Int] = [:], status: Status? = nil
    ) {
        self.sheet = sheet
        self.undoSheets = undoSheets
        self.fileURL = fileURL
        self.changeColumn = changeColumn
        self.scrollOffset = scrollOffset
        self.columnScrollMaxOffsets = columnScrollMaxOffsets
        self.status = status
    }

    func undo() -> Model {
        guard !undoSheets.isEmpty else { return self }
        var undoSheets = self.undoSheets
        let sheet = undoSheets.removeLast()
        return Model(
            sheet: sheet, undoSheets: undoSheets, fileURL: fileURL, changeColumn: changeColumn,
            scrollOffset: scrollOffset,
            columnScrollMaxOffsets: columnScrollMaxOffsets,
            status: status)
    }

    func replace(sheet: Sheet) -> Model {
        Model(
            sheet: sheet, undoSheets: undoSheets + [self.sheet], fileURL: fileURL,
            changeColumn: changeColumn, scrollOffset: scrollOffset,
            columnScrollMaxOffsets: columnScrollMaxOffsets,
            status: status)
    }

    func replace(scrollOffset: Int) -> Model {
        Model(
            sheet: sheet, undoSheets: undoSheets, fileURL: fileURL, changeColumn: changeColumn,
            scrollOffset: scrollOffset,
            columnScrollMaxOffsets: columnScrollMaxOffsets,
            status: status)
    }

    func replace(changeColumn: Int?) -> Model {
        Model(
            sheet: sheet, undoSheets: undoSheets, fileURL: fileURL, changeColumn: changeColumn,
            scrollOffset: scrollOffset,
            columnScrollMaxOffsets: columnScrollMaxOffsets,
            status: status)
    }

    func replace(column: Int, scrollSize: Size, mask: Rect) -> Model {
        var columnScrollMaxOffsets = self.columnScrollMaxOffsets
        columnScrollMaxOffsets[column] = scrollSize.height - mask.height
        return Model(
            sheet: sheet, undoSheets: undoSheets, fileURL: fileURL, changeColumn: changeColumn,
            scrollOffset: scrollOffset,
            columnScrollMaxOffsets: columnScrollMaxOffsets,
            status: status)
    }

    func replace(status: Status?) -> Model {
        Model(
            sheet: sheet, undoSheets: undoSheets, fileURL: fileURL, changeColumn: changeColumn,
            scrollOffset: scrollOffset,
            columnScrollMaxOffsets: columnScrollMaxOffsets,
            status: status)
    }

    func replace(status: String) -> Model {
        Model(
            sheet: sheet, undoSheets: undoSheets, fileURL: fileURL, changeColumn: changeColumn,
            scrollOffset: scrollOffset,
            columnScrollMaxOffsets: columnScrollMaxOffsets,
            status: (msg: status, timeout: Date().timeIntervalSince1970 + STATUS_TIMEOUT))
    }
}
