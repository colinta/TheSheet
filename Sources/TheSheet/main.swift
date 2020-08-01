import Ashen

try! Ashen(
    Program(
        initial(
            Model(
                columns: [
                    SheetColumn(
                        title: "Actions",
                        controls: [
                            .countable(title: "Sorcery Points", current: 4, max: 4),
                            .countable(title: "Ki Points", current: 3, max: 3),
                            .slots(
                                "Spell Slots",
                                [
                                    Slot(title: "1", current: 4, max: 4),
                                    Slot(title: "2", current: 3, max: 3),
                                    Slot(title: "3", current: 1, max: 1),
                                ]),
                            .stats(
                                "Attack Stats",
                                [
                                    Stat(title: "A.C.", value: .const(15)),
                                    Stat(title: "Prof.", value: .modifier(2)),
                                    Stat(title: "Str", value: .modifier(1)),
                                    Stat(title: "Dex", value: .modifier(2)),
                                    Stat(title: "Spell", value: .modifier(5)),
                                ]),
                            .attack(
                                Attack(
                                    title: "Dagger", check: .modifier(3),
                                    damage: [.dice(.d4), .formula(.modifier(1))], type: "piercing",
                                    description: "Finesse, Light, Thrown (range 20/60)")),
                        ]), SheetColumn(title: "Inventory", controls: []),
                    SheetColumn(title: "Spells", controls: []),
                    SheetColumn(
                        title: "Stats",
                        controls: [.countable(title: "Hit Points", current: 33, max: 33)]),
                ], formulas: [:])), update, render))
