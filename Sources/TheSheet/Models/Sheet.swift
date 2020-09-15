////
///  Sheet.swift
//

import Ashen

struct Sheet {
    enum Message {
        case columnMessage(Int, SheetColumn.Message)
    }

    typealias Mod = (Sheet) -> Sheet

    let visibleColumnsCount: Int
    let columns: [SheetColumn]
    let formulas: [Formula]

    init(visibleColumnsCount: Int, columns: [SheetColumn]) {
        self.visibleColumnsCount = visibleColumnsCount
        self.columns = columns
        self.formulas = Sheet.formulas(columns)
    }

    static private func formulas(_ columns: [SheetColumn]) -> [Formula] {
        columns.reduce([]) { memo, column in
            Operation.merge(memo, with: column.formulas)
        }
    }

    func findOperation(variable: String) -> Operation? {
        formulas.first(where: { $0.is(named: variable) })?.operation
    }

    func replace(visibleColumnsCount: Int) -> Sheet {
        Sheet(
            visibleColumnsCount: visibleColumnsCount, columns: columns)
    }

    func replace(columns: [SheetColumn]) -> Sheet {
        Sheet(
            visibleColumnsCount: visibleColumnsCount, columns: columns)
    }

    func replace(column: SheetColumn, at columnIndex: Int) -> Sheet {
        Sheet(
            visibleColumnsCount: visibleColumnsCount,
            columns: columns.replacing(column, at: columnIndex))
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
        case let .columnMessage(changeIndex, message):
            var mod: Mod? = nil
            let columns = self.columns.enumerated().map { (index, column) -> SheetColumn in
                guard index == changeIndex else { return column }
                let (newColumn, newMod) = column.update(sheet: self, message: message)
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
        case visibleColumnsCount
        case columns
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        columns = try values.decode([SheetColumn].self, forKey: .columns)
        visibleColumnsCount = try values.decode(Int.self, forKey: .visibleColumnsCount)
        formulas = Sheet.formulas(columns)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(visibleColumnsCount, forKey: .visibleColumnsCount)
        try container.encode(columns, forKey: .columns)
    }
}
