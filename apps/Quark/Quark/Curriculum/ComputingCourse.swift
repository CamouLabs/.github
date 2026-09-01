//
//  ComputingCourse.swift
//  Quark
//
//  Curated computing content: procedures and loops, binary, cost of an
//  algorithm, and choosing the right data structure.
//

import Foundation

enum ComputingCourse {
    static let course = Course(
        track: .computing,
        units: [
            Unit(
                id: "computing.thinking",
                title: "Thinking in steps",
                blurb: "Procedures, loops, and the machine's own number system.",
                lessons: [algorithms, binary]
            ),
            Unit(
                id: "computing.scale",
                title: "Code that scales",
                blurb: "What gets slow, and what to store things in.",
                lessons: [bigO, structures]
            )
        ]
    )

    // MARK: - Algorithms

    static let algorithms = Lesson(
        id: "computing.algorithms",
        title: "Algorithms and loops",
        goal: "Trace a loop by hand and count how often a body runs.",
        facts: [
            "An algorithm is a finite sequence of unambiguous steps.",
            "A loop repeats its body while its condition holds.",
            "Nested loops multiply: an outer loop of m and inner of n runs m × n times.",
            "A loop whose condition never changes never ends."
        ],
        exercises: [
            .order(
                "computing.algorithms.1",
                lesson: "computing.algorithms",
                "Order the steps of an algorithm that finds the largest number in a list.",
                steps: [
                    "Take the first item as the best so far",
                    "Look at the next item",
                    "If it beats the best so far, replace it",
                    "Repeat to the end of the list",
                    "Return the best so far"
                ],
                why: "One pass, one variable. This is a linear scan, and it is O(n).",
                hint: "You need something to compare against before you can compare."
            ),
            .number(
                "computing.algorithms.2",
                lesson: "computing.algorithms",
                "A loop runs `for i in 1...5 { print(i) }`. How many lines are printed?",
                answer: 5,
                check: "5",
                why: "The range 1...5 is inclusive at both ends: 1, 2, 3, 4, 5.",
                hint: "Count the values the range contains.",
                difficulty: .gentle
            ),
            .number(
                "computing.algorithms.3",
                lesson: "computing.algorithms",
                "How many times does the inner body run? `for i in 0..<3 { for j in 0..<4 { … } }`",
                answer: 12,
                check: "3 * 4",
                why: "The inner loop runs 4 times for each of the 3 outer passes: 3 × 4 = 12.",
                hint: "Nested loops multiply rather than add."
            ),
            .choice(
                "computing.algorithms.4",
                lesson: "computing.algorithms",
                "A loop whose condition never becomes false is:",
                options: ["Efficient", "An infinite loop", "A function", "A recursion"],
                correct: 1,
                why: "Nothing inside the loop changes the condition, so it never exits.",
                hint: "Ask what has to change for the loop to stop.",
                difficulty: .gentle
            ),
            .truth(
                "computing.algorithms.5",
                lesson: "computing.algorithms",
                "An algorithm that is supposed to return a result must be guaranteed to terminate.",
                answer: true,
                why: "Termination is part of the definition. A procedure that may never stop cannot promise a result.",
                hint: "What would 'the answer' mean for a program that never finishes?"
            )
        ]
    )

    // MARK: - Binary

    static let binary = Lesson(
        id: "computing.binary",
        title: "Binary and bits",
        goal: "Convert small binary numbers and reason about storage size.",
        facts: [
            "Binary place values are powers of two: 1, 2, 4, 8, 16, and so on.",
            "One byte is 8 bits and holds 256 different values.",
            "Adding one bit doubles the number of values you can represent.",
            "Base-16 is called hexadecimal and packs four bits per digit."
        ],
        exercises: [
            .number(
                "computing.binary.1",
                lesson: "computing.binary",
                "What is binary 1011 in decimal?",
                answer: 11,
                check: "8 + 2 + 1",
                why: "The bits are 8, 4, 2, 1. With the 4 switched off: 8 + 2 + 1 = 11.",
                hint: "Write the place values above the digits, then add the ones that are on."
            ),
            .number(
                "computing.binary.2",
                lesson: "computing.binary",
                "How many different values fit in 8 bits?",
                answer: 256,
                check: "2^8",
                why: "Each bit doubles the possibilities: 2⁸ = 256.",
                hint: "Two choices per bit, eight bits."
            ),
            .choice(
                "computing.binary.3",
                lesson: "computing.binary",
                "One byte is:",
                options: ["4 bits", "8 bits", "16 bits", "1024 bits"],
                correct: 1,
                why: "Eight bits to the byte, which is why a byte holds 256 values.",
                hint: "It is the smaller of the two plausible answers.",
                difficulty: .gentle
            ),
            .truth(
                "computing.binary.4",
                lesson: "computing.binary",
                "Adding one bit doubles the number of values you can store.",
                answer: true,
                why: "Each new bit can be 0 or 1 alongside everything you already had.",
                hint: "Compare 2³ with 2⁴.",
                difficulty: .gentle
            ),
            .text(
                "computing.binary.5",
                lesson: "computing.binary",
                "Numbers written in base 16 are called ___.",
                accepted: ["hexadecimal", "hex"],
                why: "Hexadecimal uses 0–9 then A–F, so one digit covers exactly four bits.",
                hint: "Programmers shorten the word to three letters."
            )
        ]
    )

    // MARK: - Big-O

    static let bigO = Lesson(
        id: "computing.bigo",
        title: "Big-O intuition",
        goal: "Predict how a program's running time grows with its input.",
        facts: [
            "O(1) does not grow with input size; O(n) grows in step with it.",
            "Binary search halves the search space each step, giving about log₂ n steps.",
            "log₂ 1024 is 10, so binary search on 1024 items takes at most 10 steps.",
            "Nested loops over the same input give O(n²), which grows painfully fast."
        ],
        exercises: [
            .choice(
                "computing.bigo.1",
                lesson: "computing.bigo",
                "Binary search on a sorted list of n items takes about:",
                options: ["n steps", "n² steps", "log₂ n steps", "one step"],
                correct: 2,
                why: "Each comparison throws away half of what is left, so the count is logarithmic.",
                hint: "How many times can you halve n before you reach 1?"
            ),
            .number(
                "computing.bigo.2",
                lesson: "computing.bigo",
                "Binary search over 1024 sorted items: how many steps in the worst case?",
                answer: 10,
                check: "10",
                why: "1024 = 2¹⁰, so ten halvings take you from 1024 down to 1.",
                hint: "Keep halving 1024 and count."
            ),
            .truth(
                "computing.bigo.3",
                lesson: "computing.bigo",
                "An O(n²) algorithm can be perfectly fine at n = 10 and unusable at n = 100000.",
                answer: true,
                why: "100 operations versus ten billion. Complexity only matters at scale, but at scale it matters completely.",
                hint: "Square both values and compare."
            ),
            .match(
                "computing.bigo.4",
                lesson: "computing.bigo",
                "Match each operation to its cost.",
                pairs: [
                    ("Array lookup by index", "O(1)"),
                    ("Linear search", "O(n)"),
                    ("Binary search", "O(log n)"),
                    ("Nested loops over n", "O(n²)")
                ],
                why: "Direct access is constant, one pass is linear, halving is logarithmic, and pairs of items are quadratic.",
                hint: "Match the cheapest one first."
            ),
            .number(
                "computing.bigo.5",
                lesson: "computing.bigo",
                "A linear scan of 2000 items takes 4 ms. Roughly how long would 6000 items take?",
                answer: 12,
                tolerance: 0.5,
                unit: "ms",
                check: "4 * 3",
                why: "Linear means triple the input, triple the time: 4 × 3 = 12 ms.",
                hint: "6000 is three times 2000.",
                difficulty: .stretch
            )
        ]
    )

    // MARK: - Data structures

    static let structures = Lesson(
        id: "computing.structures",
        title: "Picking a data structure",
        goal: "Choose the structure that makes your operation cheap.",
        facts: [
            "An array gives fast lookup by index.",
            "A stack is last in, first out; a queue is first in, first out.",
            "A set answers membership questions quickly.",
            "A dictionary maps keys to values.",
            "A tree has nodes and a single root; a balanced binary tree of k levels holds 2^k - 1 nodes."
        ],
        exercises: [
            .match(
                "computing.structures.1",
                lesson: "computing.structures",
                "Match each structure to what it is good at.",
                pairs: [
                    ("Array", "Lookup by position"),
                    ("Stack", "Last in, first out"),
                    ("Queue", "First in, first out"),
                    ("Dictionary", "Key to value")
                ],
                why: "Each structure trades away some operations to make others cheap.",
                hint: "Two of these differ only in which end you remove from."
            ),
            .choice(
                "computing.structures.2",
                lesson: "computing.structures",
                "You need to ask 'have I seen this before?' a million times. Best choice:",
                options: ["Array", "Set", "Stack", "Queue"],
                correct: 1,
                why: "A set answers membership in roughly constant time; scanning an array is O(n) every single time.",
                hint: "Which structure exists specifically to answer that question?"
            ),
            .truth(
                "computing.structures.3",
                lesson: "computing.structures",
                "A stack removes the item that has been waiting the longest.",
                answer: false,
                why: "That is a queue. A stack removes the most recent item — think of a stack of plates.",
                hint: "Picture taking a plate off a pile.",
                difficulty: .gentle
            ),
            .text(
                "computing.structures.4",
                lesson: "computing.structures",
                "A structure of nodes with exactly one root and no cycles is a ___.",
                accepted: ["tree"],
                why: "Trees model hierarchies: file systems, syntax, org charts.",
                hint: "It is named after something with branches."
            ),
            .number(
                "computing.structures.5",
                lesson: "computing.structures",
                "How many nodes fit in a full binary tree with 3 levels?",
                answer: 7,
                check: "2^3 - 1",
                why: "1 + 2 + 4 = 7, which is 2³ - 1.",
                hint: "Each level holds twice as many nodes as the one above it.",
                difficulty: .stretch
            )
        ]
    )
}
