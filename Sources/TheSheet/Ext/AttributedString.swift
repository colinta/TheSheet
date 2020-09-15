////
///  AttributedString.swift
//

import Ashen

extension AttributedString {
    func indented() -> AttributedString {
        let indent = [
            AttributedCharacter(character: " ", attributes: []),
            AttributedCharacter(character: " ", attributes: []),
        ]
        var next: [AttributedCharacter] = []
        let ret = AttributedString(
            characters:
                indent
                + self.attributedCharacters.flatMap { c -> [AttributedCharacter] in
                    if c.character == "\n" {
                        next = indent
                        return [c]
                    }
                    let r = next + [c]
                    next = []
                    return r
                })
        return ret
    }
}
