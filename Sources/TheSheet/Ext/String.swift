////
///  String.swift
//

extension String {
    func hasAnyPrefix(_ prefixes: String...) -> Bool {
        prefixes.first(where: { hasPrefix($0) }) != nil
    }

    func removingPrefix(_ prefixes: String...) -> String? {
        for pre in prefixes {
            guard hasPrefix(pre) else { continue }
            return String(dropFirst(pre.count))
        }
        return nil
    }

    func removingSuffix(_ suffixes: String...) -> String? {
        for suffix in suffixes {
            guard hasSuffix(suffix) else { continue }
            return String(dropLast(suffix.count))
        }
        return nil
    }
}
