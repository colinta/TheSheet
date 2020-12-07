////
///  CreateSheet.swift
//

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
                            Stat(title: "A.C.", value: .variable("armorClass")),
                            Stat(title: "Prof.", value: .variable("proficiencyBonus")),
                            Stat(title: "Str", value: .variable("STR.Mod")),
                            Stat(title: "Dex", value: .variable("DEX.Mod")),
                        ]),
                ]),
            SheetColumn(title: "Inventory", controls: []),
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
                            variable: "strengthAttackBonus",
                            operation: .variable("STR.Mod")
                        ),
                        Formula(
                            variable: "dexterityAttackBonus",
                            operation: .variable("DEX.Mod")
                        ),
                        Formula(
                            variable: "armorClass",
                            operation:
                                .add([
                                    .integer(10),
                                    .variable("DEX.Mod"),
                                ])
                        ),
                    ])
                ],
                isFormulaColumn: true),
        ]
    )
}
