////
///  Formula
//

struct Formula: Codable {
    let variable: String
    let operation: Operation

    func `is`(named: String) -> Bool {
        variable == named || variable.lowercased() == named.lowercased()
    }
}
