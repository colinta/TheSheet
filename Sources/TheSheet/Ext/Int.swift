////
///  Int.swift
//

extension Int {
    public var toModString: String {
        if self < 0 {
            return "\(self)"
        } else {
            return "+\(self)"
        }
    }
}
