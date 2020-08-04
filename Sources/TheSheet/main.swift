import Ashen
import Foundation

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

try! main()

func createSheet() -> Sheet {
    Sheet(
        selectedColumns: [0, 1, 2, 3],
        columns: [
            SheetColumn(
                title: "Actions",
                controls: [
                    .pointsTracker(
                        Points(
                            title: "Sorcery Points", current: 4, max: 4, shouldResetOnLongRest: true
                        )),
                    .pointsTracker(
                        Points(title: "Ki Points", current: 3, max: 3, shouldResetOnLongRest: true)),
                    .stats(
                        "Attack Stats",
                        [
                            Stat(title: "A.C.", value: .const(15)),
                            Stat(title: "Prof.", value: .modifier(2)),
                            Stat(title: "Str", value: .modifier(1)),
                            Stat(title: "Dex", value: .modifier(2)),
                            Stat(title: "Spell", value: .modifier(5)),
                        ]),
                    .action(
                        Action(
                            title: "Dagger", check: .modifier(3),
                            damage: [.dice(.d4), .formula(.modifier(1))], type: "piercing",
                            description: "Finesse, Light, Thrown (range 20/60)")),
                    .action(
                        Action(
                            title: "Quarterstaff",
                            subactions: [
                                Action.Sub(
                                    title: "One Handed",
                                    check: .modifier(3),
                                    damage: [.dice(.d6), .formula(.modifier(1))],
                                    type: "bludgeoning"),
                                Action.Sub(
                                    title: "Two Handed",
                                    check: .modifier(3),
                                    damage: [.dice(.d8), .formula(.modifier(1))],
                                    type: "bludgeoning"),
                            ], description: "Versatile"
                        )),
                ]), SheetColumn(title: "Inventory", controls: []),
            SheetColumn(
                title: "Spells",
                controls: [
                    .slots(
                        "Spell Slots",
                        [
                            Slot(title: "1", current: 4, max: 4, shouldResetOnLongRest: true),
                            Slot(title: "2", current: 3, max: 3, shouldResetOnLongRest: true),
                            Slot(title: "3", current: 1, max: 1, shouldResetOnLongRest: true),
                        ]),
                    .action(
                        Action(
                            title: "Chill Touch",
                            level: "Cantrip",
                            check: .modifier(5),
                            damage: [.dice(.d8)],
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
                    .restButtons,
                    .pointsTracker(
                        Points(
                            title: "Hit Points", current: 33, max: 33, shouldResetOnLongRest: true)),
                ]),
        ],
        formulas: [:]
    )
}
