////
///  Model.swift
//

struct Model {
    typealias Status = (msg: String, timeout: TimeInterval)

    let offset: Int
    let sheet: Sheet
    let changeColumn: Int?
    let fileURL: URL?
    let status: Status?

    func replace(sheet: Sheet) -> Model {
        Model(
            offset: offset, sheet: sheet, changeColumn: changeColumn, fileURL: fileURL,
            status: status)
    }

    func replace(offset: Int) -> Model {
        Model(
            offset: max(0, offset), sheet: sheet, changeColumn: changeColumn, fileURL: fileURL,
            status: status)
    }

    func replace(changeColumn: Int?) -> Model {
        Model(
            offset: offset, sheet: sheet, changeColumn: changeColumn, fileURL: fileURL,
            status: status)
    }

    func replace(status: Status?) -> Model {
        Model(
            offset: offset, sheet: sheet, changeColumn: changeColumn, fileURL: fileURL,
            status: status)
    }

    func replace(status: String) -> Model {
        Model(
            offset: offset, sheet: sheet, changeColumn: changeColumn, fileURL: fileURL,
            status: (msg: status, timeout: Date().timeIntervalSince1970 + STATUS_TIMEOUT))
    }
}
