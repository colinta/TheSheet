////
///  Sheet.swift
//

import Ashen

struct Sheet {
    enum Message {
        case column(Int, SheetColumn.Message)
    }

    typealias Mod = (Sheet) -> Sheet

    let columnsOrder: [Int]
    let visibleColumns: Int
    let columns: [SheetColumn]
    let formulas: Formula.Lookup
    private var formulaMemo: [String: Formula.Value] = [:]

    init(columnsOrder: [Int], visibleColumns: Int, columns: [SheetColumn]) {
        self.columnsOrder = Sheet.fixColumns(columnsOrder, count: columns.count)
        self.visibleColumns = visibleColumns
        self.columns = columns
        self.formulas = Sheet.formulas(columns)
    }

    static private func fixColumns(_ columnsOrder: [Int], count: Int) -> [Int] {
        var missingColumns: [Int] = Array(0..<count)
        let fixedColumns = columnsOrder.reduce([Int]()) { memo, index in
            guard !memo.contains(index) else { return memo }
            missingColumns = missingColumns.filter { $0 != index }
            return memo + [index]
        }

        return fixedColumns + missingColumns
    }

    static private func formulas(_ columns: [SheetColumn]) -> Formula.Lookup {
        columns.reduce([:]) { memo, column in
            Formula.merge(memo, with: column.formulas)
        }
    }

    func replace(columnsOrder: [Int]) -> Sheet {
        Sheet(columnsOrder: columnsOrder, visibleColumns: visibleColumns, columns: columns)
    }

    func replace(visibleColumns: Int) -> Sheet {
        Sheet(columnsOrder: columnsOrder, visibleColumns: visibleColumns, columns: columns)
    }

    func replace(columns: [SheetColumn]) -> Sheet {
        Sheet(columnsOrder: columnsOrder, visibleColumns: visibleColumns, columns: columns)
    }

    static func mapControls(_ map: @escaping (SheetControl) -> SheetControl) -> (Sheet) -> Sheet {
        { sheet in sheet.mapControls(map) }
    }

    func mapColumns(_ map: @escaping (SheetColumn) -> SheetColumn) -> Sheet {
        replace(columns: columns.map(map))
    }

    func mapControls(_ map: @escaping (SheetControl) -> SheetControl) -> Sheet {
        mapColumns { column in
            column.replace(controls: column.controls.map(map))
        }
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

extension Sheet: Codable {
    enum CodingKeys: String, CodingKey {
        case columnsOrder
        case visibleColumns
        case columns
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let savedOrder = try values.decode([Int].self, forKey: .columnsOrder)
        let columns = try values.decode([SheetColumn].self, forKey: .columns)
        let fixedColumns = Sheet.fixColumns(savedOrder, count: columns.count)

        columnsOrder = fixedColumns
        self.columns = columns
        visibleColumns = try values.decode(Int.self, forKey: .visibleColumns)
        formulas = Sheet.formulas(columns)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(columnsOrder, forKey: .columnsOrder)
        try container.encode(visibleColumns, forKey: .visibleColumns)
        try container.encode(columns, forKey: .columns)
    }
}
