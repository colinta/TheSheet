import Foundation
import ArgumentParser
import Ashen

@main
struct Main: ParsableCommand {
    @Option(name: [.customShort("f"), .customLong("filename")])
    var filename: String?

    func run() throws {
        // debugSilenced(true)
        // let op: Operation = .if(.bool(true), .dice(Dice(n: 1, d: 4)), .if(.bool(true), .dice(Dice(n: 1, d: 4)), .dice(Dice(n: 1, d: 6))))
        // let sheet = Sheet(visibleColumnsCount: 0, columns: [])
        // print("=============== \(#file) line \(#line) ===============")
        // print("op: \(op.toAttributed(sheet).string)")

        let fileURL = filename.map { URL(fileURLWithPath: $0) }
        let sheet: Sheet
        if let fileURL = fileURL,
            let data = try? String(contentsOf: fileURL).data(using: .utf8)
        {
            let coder = JSONDecoder()
            sheet = try coder.decode(Sheet.self, from: data)
        } else {
            sheet = createSheet()
        }

        try ashen(
            Ashen.Program(
                TheSheet.initial(
                    sheet: sheet,
                    fileURL: fileURL
                ), TheSheet.update, TheSheet.render))
    }
}
