////
///  Model.swift
//

import Ashen
import Foundation

let STATUS_TIMEOUT: TimeInterval = 3

struct Model {
    typealias Status = (msg: String, timeout: TimeInterval)

    enum Editing {
        case changeColumn(Int)
        case editColumn(Int)
        case addToColumn(Int)
        case editControl(column: Int, control: Int, editor: EditableControl)
        case relocateControl(column: Int, control: Int)
        case none
    }

    let sheet: Sheet
    let undoSheets: [Sheet]
    let fileURL: URL?
    let firstVisibleColumn: Int
    let columnScrollOffset: Int
    let modalScrollOffset: Int
    let editing: Editing
    let columnScrollMaxOffsets: [Int: Int]
    let modalScrollMaxOffset: Int
    let status: Status?

    var canUndo: Bool { !undoSheets.isEmpty }
    var columnScrollMaxOffset: Int {
        let visibleColumns = sheet.columnsOrder[
            firstVisibleColumn..<firstVisibleColumn + sheet.visibleColumnsCount]
        return columnScrollMaxOffsets.reduce(
            nil as Int?,
            { memo, index_height in
                let (index, height) = index_height
                guard visibleColumns.contains(index) else { return memo }
                return max(memo ?? 0, height)
            }) ?? 0
    }

    var changingColumn: Int? {
        guard case let .changeColumn(editingColumn) = editing else { return nil }
        return editingColumn
    }
    var editingColumn: Int? {
        guard case let .editColumn(editingColumn) = editing else { return nil }
        return editingColumn
    }
    var addingToColumn: Int? {
        guard case let .addToColumn(editingColumn) = editing else { return nil }
        return editingColumn
    }
    var editingControl: (column: Int, control: Int, editor: EditableControl)? {
        guard case let .editControl(column, control, editor) = editing else { return nil }
        return (column, control, editor)
    }
    var relocatingControl: (column: Int, control: Int)? {
        guard case let .relocateControl(column, control) = editing else { return nil }
        return (column, control)
    }

    init(
        sheet: Sheet, undoSheets: [Sheet] = [], fileURL: URL? = nil,
        firstVisibleColumn: Int = 0,
        columnScrollOffset: Int = 0, modalScrollOffset: Int = 0,
        editing: Editing = .none,
        columnScrollMaxOffsets: [Int: Int] = [:], modalScrollMaxOffset: Int = 0,
        status: Status? = nil
    ) {
        self.sheet = sheet
        self.undoSheets = undoSheets
        self.fileURL = fileURL
        self.firstVisibleColumn = firstVisibleColumn
        self.columnScrollOffset = columnScrollOffset
        self.modalScrollOffset = modalScrollOffset
        self.editing = editing
        self.columnScrollMaxOffsets = columnScrollMaxOffsets
        self.modalScrollMaxOffset = modalScrollMaxOffset
        self.status = status
    }

    func undo() -> Model {
        guard !undoSheets.isEmpty else { return self }
        var undoSheets = self.undoSheets
        let sheet = undoSheets.removeLast()
        return Model(
            sheet: sheet, undoSheets: undoSheets, fileURL: fileURL,
            firstVisibleColumn: firstVisibleColumn,
            columnScrollOffset: columnScrollOffset, modalScrollOffset: modalScrollOffset,
            editing: .none,
            columnScrollMaxOffsets: columnScrollMaxOffsets,
            modalScrollMaxOffset: modalScrollMaxOffset,
            status: status)
    }

    func replace(sheet: Sheet) -> Model {
        let columnScrollOffset = max(0, min(self.columnScrollOffset, columnScrollMaxOffset))
        return Model(
            sheet: sheet, undoSheets: undoSheets.appending(self.sheet), fileURL: fileURL,
            firstVisibleColumn: firstVisibleColumn,
            columnScrollOffset: columnScrollOffset, modalScrollOffset: modalScrollOffset,
            editing: editing,
            columnScrollMaxOffsets: columnScrollMaxOffsets,
            modalScrollMaxOffset: modalScrollMaxOffset,
            status: status)
    }

    func addControl(_ control: SheetControl, toColumn columnIndex: Int) -> Model {
        replace(
            sheet: sheet.replace(
                columns: sheet.columns.modifying(
                    { column in
                        column.replace(controls: column.controls.appending(control))
                    }, at: columnIndex)))
    }

    func replace(
        control controlIndex: Int, inColumn columnIndex: Int, with newControl: SheetControl
    ) -> Model {
        replace(
            sheet: sheet.replace(
                columns: sheet.columns.modifying(
                    { column in
                        column.replace(
                            controls: column.controls.replacing(newControl, at: controlIndex))
                    }, at: columnIndex)))
    }

    func replace(changeColumn column: Int) -> Model {
        let columnScrollOffset = max(0, min(self.columnScrollOffset, columnScrollMaxOffset))
        return Model(
            sheet: sheet, undoSheets: undoSheets, fileURL: fileURL,
            firstVisibleColumn: firstVisibleColumn,
            columnScrollOffset: columnScrollOffset, modalScrollOffset: modalScrollOffset,
            editing: .changeColumn(column),
            columnScrollMaxOffsets: columnScrollMaxOffsets,
            modalScrollMaxOffset: modalScrollMaxOffset,
            status: status)
    }

    func replace(editColumn column: Int) -> Model {
        Model(
            sheet: sheet, undoSheets: undoSheets, fileURL: fileURL,
            firstVisibleColumn: firstVisibleColumn,
            columnScrollOffset: columnScrollOffset, modalScrollOffset: modalScrollOffset,
            editing: .editColumn(column),
            columnScrollMaxOffsets: columnScrollMaxOffsets,
            modalScrollMaxOffset: modalScrollMaxOffset,
            status: status)
    }

    func replace(addToColumn column: Int) -> Model {
        Model(
            sheet: sheet, undoSheets: undoSheets, fileURL: fileURL,
            firstVisibleColumn: firstVisibleColumn,
            columnScrollOffset: columnScrollOffset, modalScrollOffset: modalScrollOffset,
            editing: .addToColumn(column),
            columnScrollMaxOffsets: columnScrollMaxOffsets,
            modalScrollMaxOffset: modalScrollMaxOffset,
            status: status)
    }

    func replace(editControl control: Int, inColumn column: Int, editor: EditableControl) -> Model {
        Model(
            sheet: sheet, undoSheets: undoSheets, fileURL: fileURL,
            firstVisibleColumn: firstVisibleColumn,
            columnScrollOffset: columnScrollOffset, modalScrollOffset: modalScrollOffset,
            editing: .editControl(column: column, control: control, editor: editor),
            columnScrollMaxOffsets: columnScrollMaxOffsets,
            modalScrollMaxOffset: modalScrollMaxOffset,
            status: status)
    }

    func replace(relocateControl control: Int, inColumn column: Int) -> Model {
        Model(
            sheet: sheet, undoSheets: undoSheets, fileURL: fileURL,
            firstVisibleColumn: firstVisibleColumn,
            columnScrollOffset: columnScrollOffset, modalScrollOffset: modalScrollOffset,
            editing: .relocateControl(column: column, control: control),
            columnScrollMaxOffsets: columnScrollMaxOffsets,
            modalScrollMaxOffset: modalScrollMaxOffset,
            status: status)
    }

    func stopEditing() -> Model {
        Model(
            sheet: sheet, undoSheets: undoSheets, fileURL: fileURL,
            firstVisibleColumn: firstVisibleColumn,
            columnScrollOffset: columnScrollOffset, modalScrollOffset: modalScrollOffset,
            editing: .none,
            columnScrollMaxOffsets: columnScrollMaxOffsets,
            modalScrollMaxOffset: modalScrollMaxOffset,
            status: status)
    }

    func replace(columnScrollOffset: Int) -> Model {
        Model(
            sheet: sheet, undoSheets: undoSheets, fileURL: fileURL,
            firstVisibleColumn: firstVisibleColumn,
            columnScrollOffset: columnScrollOffset, modalScrollOffset: modalScrollOffset,
            editing: editing,
            columnScrollMaxOffsets: columnScrollMaxOffsets,
            modalScrollMaxOffset: modalScrollMaxOffset,
            status: status)
    }

    func replace(modalScrollOffset: Int) -> Model {
        Model(
            sheet: sheet, undoSheets: undoSheets, fileURL: fileURL,
            firstVisibleColumn: firstVisibleColumn,
            columnScrollOffset: columnScrollOffset, modalScrollOffset: modalScrollOffset,
            editing: editing,
            columnScrollMaxOffsets: columnScrollMaxOffsets,
            modalScrollMaxOffset: modalScrollMaxOffset,
            status: status)
    }

    func replace(firstVisibleColumn: Int) -> Model {
        let columnScrollOffset = max(0, min(self.columnScrollOffset, columnScrollMaxOffset))
        return Model(
            sheet: sheet, undoSheets: undoSheets, fileURL: fileURL,
            firstVisibleColumn: firstVisibleColumn,
            columnScrollOffset: columnScrollOffset, modalScrollOffset: modalScrollOffset,
            editing: .none,
            columnScrollMaxOffsets: columnScrollMaxOffsets,
            modalScrollMaxOffset: modalScrollMaxOffset,
            status: status)
    }

    func replace(column: Int, scrollViewport: LocalViewport) -> Model {
        var columnScrollMaxOffsets = self.columnScrollMaxOffsets
        columnScrollMaxOffsets[column] = scrollViewport.size.height - scrollViewport.visible.height
        return Model(
            sheet: sheet, undoSheets: undoSheets, fileURL: fileURL,
            firstVisibleColumn: firstVisibleColumn,
            columnScrollOffset: columnScrollOffset, modalScrollOffset: modalScrollOffset,
            editing: editing,
            columnScrollMaxOffsets: columnScrollMaxOffsets,
            modalScrollMaxOffset: modalScrollMaxOffset,
            status: status)
    }

    func replace(modalScrollViewport scrollViewport: LocalViewport) -> Model {
        let modalScrollMaxOffset = scrollViewport.size.height - scrollViewport.visible.height
        return Model(
            sheet: sheet, undoSheets: undoSheets, fileURL: fileURL,
            firstVisibleColumn: firstVisibleColumn,
            columnScrollOffset: columnScrollOffset, modalScrollOffset: modalScrollOffset,
            editing: editing,
            columnScrollMaxOffsets: columnScrollMaxOffsets,
            modalScrollMaxOffset: modalScrollMaxOffset,
            status: status)
    }

    func replace(status: Status?) -> Model {
        Model(
            sheet: sheet, undoSheets: undoSheets, fileURL: fileURL,
            firstVisibleColumn: firstVisibleColumn,
            columnScrollOffset: columnScrollOffset, modalScrollOffset: modalScrollOffset,
            editing: editing,
            columnScrollMaxOffsets: columnScrollMaxOffsets,
            modalScrollMaxOffset: modalScrollMaxOffset,
            status: status)
    }

    func replace(status: String) -> Model {
        Model(
            sheet: sheet, undoSheets: undoSheets, fileURL: fileURL,
            firstVisibleColumn: firstVisibleColumn,
            columnScrollOffset: columnScrollOffset, modalScrollOffset: modalScrollOffset,
            editing: editing,
            columnScrollMaxOffsets: columnScrollMaxOffsets,
            modalScrollMaxOffset: modalScrollMaxOffset,
            status: (msg: status, timeout: Date().timeIntervalSince1970 + STATUS_TIMEOUT))
    }

    func isChangingColumn(_ columnIndex: Int? = nil) -> Bool {
        guard case let .changeColumn(editingColumn) = editing
        else { return false }
        guard let columnIndex = columnIndex else { return true }
        return editingColumn == columnIndex
    }

    func isEditingColumn(_ columnIndex: Int? = nil) -> Bool {
        guard case let .editColumn(editingColumn) = editing
        else { return false }
        guard let columnIndex = columnIndex else { return true }
        return editingColumn == columnIndex
    }

    func isAddingToColumn(_ columnIndex: Int? = nil) -> Bool {
        guard case let .addToColumn(editingColumn) = editing
        else { return false }
        guard let columnIndex = columnIndex else { return true }
        return editingColumn == columnIndex
    }

    func isEditingControl() -> Bool {
        guard case .editControl = editing
        else { return false }
        return true
    }

    func isEditingControl(_ controlIndex: Int? = nil, inColumn columnIndex: Int) -> Bool {
        guard case let .editControl(editingColumn, editingControl, _) = editing,
            editingColumn == columnIndex
        else { return false }
        guard let controlIndex = controlIndex else { return true }
        return editingControl == controlIndex
    }

    func isRelocatingControl(_ controlIndex: Int, inColumn columnIndex: Int) -> Bool {
        guard case let .relocateControl(editingColumn, editingControl) = editing,
            editingColumn == columnIndex, editingControl == controlIndex
        else { return false }
        return true
    }
}
