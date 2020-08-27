////
///  Array.swift
//

extension Array {
    func modifying(_ modify: (Element) -> Element, at: Int) -> Self {
        enumerated().map { index, item in
            if index == at {
                return modify(item)
            } else {
                return item
            }
        }
    }

    func replacing(_ newItem: Element, at: Int) -> Self {
        enumerated().map { index, item in
            if index == at {
                return newItem
            } else {
                return item
            }
        }
    }

    func appending(_ newItem: Element) -> Self {
        self + [newItem]
    }

    func removing(at: Int) -> Self {
        enumerated().filter { index, _ in
            index != at
        }.map { _, item in
            item
        }
    }
}
