////
///  Sheet.swift
//

import Ashen

struct Sheet {
    enum Message {
        case column(Int, SheetColumn.Message)
    }

    typealias Mod = (Sheet) -> Sheet

    let selectedColumns: [Int]
    let columns: [SheetColumn]
    let formulas: Formula.Lookup
    private var formulaMemo: [String: Formula.Value] = [:]

    init(selectedColumns: [Int], columns: [SheetColumn]) {
        self.selectedColumns = selectedColumns
        self.columns = columns
        self.formulas = Sheet.formulas(columns)
    }

    static private func formulas(_ columns: [SheetColumn]) -> Formula.Lookup {
        columns.reduce([:]) { memo, column in
            Formula.merge(memo, with: column.formulas)
        }
    }

    func eval(_ formula: Formula, _ dontRecur: [String] = []) -> Formula.Value {
        switch formula {
        case let .integer(i):
            return .integer(i)
        case let .bool(i):
            return .bool(i)
        case let .string(str):
            return .string(str)
        case let .modifier(formula):
            let result = eval(formula, dontRecur)
            switch result {
            case let .integer(i):
                return .modifier(i)
            default:
                return result
            }
        case let .variable(name):
            guard !dontRecur.contains(name),
                let formula = formulas[name]
            else {
                return .undefined
            }
            return eval(formula, dontRecur + [name])
        case let .add(formulas):
            return Formula.reduce(formulas, self, +)
        case let .max(formulas):
            return Formula.reduce(formulas, self, Swift.max)
        case let .min(formulas):
            return Formula.reduce(formulas, self, Swift.min)
        }
    }

    func replace(selectedColumns: [Int]) -> Sheet {
        Sheet(selectedColumns: selectedColumns, columns: columns)
    }

    func replace(columns: [SheetColumn]) -> Sheet {
        Sheet(selectedColumns: selectedColumns, columns: columns)
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
        case selectedColumns
        case columns
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        selectedColumns = try values.decode([Int].self, forKey: .selectedColumns)
        columns = try values.decode([SheetColumn].self, forKey: .columns)
        formulas = Sheet.formulas(columns)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(selectedColumns, forKey: .selectedColumns)
        try container.encode(columns, forKey: .columns)
    }
}
