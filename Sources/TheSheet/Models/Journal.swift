////
///  Journal.swift
//

struct Journal: Codable {
    let title: String
    let text: String
    let isExpanded: Bool

    static let `default` = Journal(title: "", text: "", isExpanded: true)

    func replace(title: String) -> Journal {
        Journal(title: title, text: text, isExpanded: isExpanded)
    }

    func replace(text: String) -> Journal {
        Journal(title: title, text: text, isExpanded: isExpanded)
    }

    func replace(isExpanded: Bool) -> Journal {
        Journal(title: title, text: text, isExpanded: isExpanded)
    }
}
