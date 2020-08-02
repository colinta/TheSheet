////
///  Sheet.swift
//

struct Sheet {
    var selectedColumns: [Int]
    var columns: [SheetColumn]
    var formulas: [String: Formula]
}
