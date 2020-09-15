import Ashen
import Foundation
import Termbox

private func main() throws {
    let file = "gron.json"
    let fileURL = URL(fileURLWithPath: file)
    let sheet: Sheet
    if let data = try? String(contentsOf: fileURL).data(using: .utf8) {
        let coder = JSONDecoder()
        sheet = try coder.decode(Sheet.self, from: data)
    } else {
        sheet = createSheet()
    }

    try Ashen(
        Program(
            initial(
                sheet: sheet,
                fileURL: fileURL
            ), update, render))
}

// debugSilenced(true)
// let op: Operation = .if(.bool(true), .dice(Dice(n: 1, d: 4)), .if(.bool(true), .dice(Dice(n: 1, d: 4)), .dice(Dice(n: 1, d: 6))))
// let sheet = Sheet(visibleColumnsCount: 0, columns: [])
// print("=============== \(#file) line \(#line) ===============")
// print("op: \(op.toAttributed(sheet).string)")
try main()

func createSheet() -> Sheet {
    Sheet(
        visibleColumnsCount: 3,
        columns: [
            SheetColumn(
                title: "Actions",
                controls: [
                    .stats(
                        "Attack Stats",
                        [
                            Stat(title: "A.C.", value: .integer(15)),
                            Stat(title: "Prof.", value: .modifier(2)),
                            Stat(title: "Str", value: .modifier(1)),
                            Stat(title: "Dex", value: .modifier(2)),
                            Stat(title: "Spell", value: .modifier(5)),
                        ]),
                    .action(
                        Action(
                            title: "Dagger", check: .modifier(3),
                            damage: .add([.dice(Dice(n: 1, d: 4)), .modifier(1)]),
                            type: "piercing",
                            description: "Finesse, Light, Thrown (range 20/60)")),
                    .action(
                        Action(
                            title: "Quarterstaff",
                            subactions: [
                                Action.Sub(
                                    title: "One Handed",
                                    check: .modifier(3),
                                    damage: .add([.dice(Dice(n: 1, d: 6)), .modifier(1)]),
                                    type: "bludgeoning"),
                                Action.Sub(
                                    title: "Two Handed",
                                    check: .modifier(3),
                                    damage: .add([.dice(Dice(n: 1, d: 8)), .modifier(1)]),
                                    type: "bludgeoning"),
                            ], description: "Versatile"
                        )),
                ]), SheetColumn(title: "Inventory", controls: []),
            SheetColumn(
                title: "Spells",
                controls: [
                    .spellSlots(
                        SpellSlots(
                            title: "Spell Slots",
                            slots: [
                                SpellSlot(title: "1", current: 4, max: 4),
                                SpellSlot(title: "2", current: 3, max: 3),
                                SpellSlot(title: "3", current: 1, max: 1),
                            ], shouldResetOnLongRest: true)),
                    .action(
                        Action(
                            title: "Chill Touch",
                            level: "Cantrip",
                            check: .modifier(5),
                            damage: .dice(Dice(n: 1, d: 8)),
                            type: "necrotic",
                            description:
                                "Target can't regain hit points, undead have disadv on attack rolls, hand clings to target"
                        )),
                    .action(
                        Action(
                            title: "Mage Hand",
                            level: "Cantrip",
                            description:
                                "You can use the hand to manipulate an object, open an unlocked door or container, stow or retrieve an item from an open container, or pour the contents out of a vial. You can move the hand up to 30 feet each time you use it."
                        )),
                ]
            ),
            SheetColumn(
                title: "Stats",
                controls: [
                    .restButton,
                    .pointsTracker(
                        Points(
                            title: "Level", current: 1, max: 20, types: [.level],
                            shouldResetOnLongRest: true)),
                    .pointsTracker(
                        Points(
                            title: "Hit Points", current: 8, max: 8, types: [.hitPoints],
                            shouldResetOnLongRest: true)),
                ]),
            SheetColumn(
                title: "Formula",
                controls: [
                    .formulas([
                        Formula(
                            variable: "proficiencyBonus",
                            operation:
                                .add([
                                    .ceil(.divide(.variable("level"), .integer(4))),
                                    .integer(1),
                                ])
                        ),
                        Formula(
                            variable: "attackBonus",
                            operation: .variable("STR.Mod")
                        ),
                        Formula(
                            variable: "defaultArmor",
                            operation:
                                .add([
                                    .integer(10),
                                    .variable("DEX.Mod"),
                                ])
                        ),
                        Formula(
                            variable: "draconicArmor",
                            operation:
                                .add([
                                    .integer(13),
                                    .variable("DEX.Mod"),
                                ])
                        ),
                        Formula(
                            variable: "armorClass",
                            operation: .max([
                                .variable("defaultArmor"),
                                .variable("draconicArmor"),
                            ])
                        ),
                        Formula(
                            variable: "spellAttack",
                            operation:
                                .add([
                                    .variable("CHA.Mod"),
                                    .variable("proficiencyBonus"),
                                ])
                        ),
                    ])
                ],
                isFormulaColumn: true),
        ]
    )
}
