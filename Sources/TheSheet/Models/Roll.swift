////
///  Roll.swift
//

struct Roll {
    let dice: [Dice]
    let modifier: Int

    var toReadable: String {
        let diceStr = dice.map({ $0.toReadable }).joined(separator: "+")
        if modifier == 0 {
            return diceStr
        }
        return "\(diceStr)+\(modifier)"
    }

    func adding(_ roll: Roll) -> Roll {
        var newDice: [Dice] = []
        // for every die already accounted for, just add N dice of the same type.
        for die in dice {
            var newDie = die
            for moreDie in roll.dice {
                if newDie.d == moreDie.d {
                    newDie = Dice(n: newDie.n + moreDie.n, d: newDie.d)
                    break
                }
            }
            newDice.append(newDie)
        }

        // add every new die
        for moreDie in roll.dice {
            guard !newDice.contains(where: { $0.d == moreDie.d }) else { continue }
            newDice.append(moreDie)
        }

        return Roll(dice: newDice.sorted { $0.d < $1.d }, modifier: modifier + roll.modifier)
    }

    func adding(_ die: Dice) -> Roll {
        adding(Roll(dice: [die], modifier: 0))
    }

    func removing(_ newDie: Dice) -> Roll {
        let newDice: [Dice] = dice.map { die in
            guard die.d == newDie.d else { return die }
            return Dice(n: die.n - newDie.n, d: die.d)
        }.filter { $0.n > 0 }

        return Roll(dice: newDice, modifier: modifier)
    }

    func replace(modifier: Int) -> Roll {
        Roll(dice: dice, modifier: modifier)
    }
}
