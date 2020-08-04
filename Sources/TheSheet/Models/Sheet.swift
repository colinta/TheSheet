////
///  Sheet.swift
//

struct Sheet: Codable {
    enum Message {
        case column(Int, SheetColumn.Message)
    }

    typealias Mod = (Sheet) -> Sheet

    var selectedColumns: [Int]
    var columns: [SheetColumn]
    var formulas: [String: Formula]

    func replace(selectedColumns: [Int]) -> Sheet {
        Sheet(selectedColumns: selectedColumns, columns: columns, formulas: formulas)
    }

    func replace(columns: [SheetColumn]) -> Sheet {
        Sheet(selectedColumns: selectedColumns, columns: columns, formulas: formulas)
    }

    func replace(formulas: [String: Formula]) -> Sheet {
        Sheet(selectedColumns: selectedColumns, columns: columns, formulas: formulas)
    }

    func update(_ message: Message) -> Sheet {
        switch message {
        case let .column(changeIndex, message):
            var mod: Mod? = nil
            let columns = self.columns.enumerated().map { (index, column) -> SheetColumn in
                guard index == changeIndex else { return column }
                let (newColumn, newMod) = column.update(message)
                mod = newMod
                return newColumn
            }
            let sheet = replace(columns: columns)
            return mod?(sheet) ?? sheet
        }
    }
}
