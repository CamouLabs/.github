//
//  MathCourse.swift
//  Quark
//
//  Curated mathematics content. Every numeric item carries a `check`
//  expression that re-derives its own answer, so the harness can prove the
//  curriculum is self-consistent before anyone ships it.
//

import Foundation

enum MathCourse {
    static let course = Course(
        track: .math,
        units: [
            Unit(
                id: "math.number",
                title: "Number sense",
                blurb: "Fractions and percentages you can do in your head.",
                lessons: [fractions, percentages]
            ),
            Unit(
                id: "math.algebra",
                title: "Algebra starts",
                blurb: "Find the unknown, then draw it.",
                lessons: [solving, slope]
            )
        ]
    )

    // MARK: - Fractions

    static let fractions = Lesson(
        id: "math.fractions",
        title: "Fractions that click",
        goal: "Compare and combine fractions without reaching for a calculator.",
        facts: [
            "A fraction is a division: 3/4 means 3 divided by 4, or 0.75.",
            "The top number is the numerator; the bottom number is the denominator.",
            "Comparing fractions is easiest as decimals: 3/8 is 0.375 and 1/2 is 0.5.",
            "To add fractions, rewrite them over a common denominator first.",
            "For the same numerator, a bigger denominator means a smaller value."
        ],
        exercises: [
            .choice(
                "math.fractions.1",
                lesson: "math.fractions",
                "Which of these fractions is the largest?",
                options: ["3/8", "2/5", "1/2", "4/9"],
                correct: 2,
                why: "As decimals: 3/8 = 0.375, 2/5 = 0.4, 4/9 ≈ 0.444, and 1/2 = 0.5.",
                hint: "Turn each one into a decimal and compare.",
                difficulty: .gentle
            ),
            .truth(
                "math.fractions.2",
                lesson: "math.fractions",
                "1/3 is larger than 0.3.",
                answer: true,
                why: "1/3 = 0.333…, which is just over 0.3.",
                hint: "Divide 1 by 3 and look at the third decimal place."
            ),
            .number(
                "math.fractions.3",
                lesson: "math.fractions",
                "What is 3/4 + 1/8?",
                answer: 0.875,
                tolerance: 0.001,
                check: "3/4 + 1/8",
                why: "3/4 is 6/8, and 6/8 + 1/8 = 7/8 = 0.875. Typing 7/8 works too.",
                hint: "Rewrite 3/4 in eighths before you add."
            ),
            .order(
                "math.fractions.4",
                lesson: "math.fractions",
                "Put these fractions in order, smallest first.",
                steps: ["1/5", "1/4", "1/3", "1/2"],
                why: "Same numerator, so the larger the denominator, the smaller the slice: 0.2, 0.25, 0.33, 0.5.",
                hint: "Cutting a cake into more pieces makes each piece smaller."
            ),
            .text(
                "math.fractions.5",
                lesson: "math.fractions",
                "What do you call the number below the line in a fraction?",
                accepted: ["denominator"],
                why: "The denominator says how many equal parts the whole is split into.",
                hint: "It shares a root with 'denomination' — the size of the unit.",
                difficulty: .gentle
            )
        ]
    )

    // MARK: - Percentages

    static let percentages = Lesson(
        id: "math.percentages",
        title: "Percentages in the wild",
        goal: "Handle discounts, increases, and 'what percent of' questions.",
        facts: [
            "Percent means per hundred: 25% is 25/100, or 0.25.",
            "A 25% discount leaves 75% of the price, so multiply by 0.75.",
            "To find what percent a is of b, compute a divided by b, then times 100.",
            "A percentage increase followed by the same percentage decrease does not return to the start."
        ],
        exercises: [
            .number(
                "math.percentages.1",
                lesson: "math.percentages",
                "A jacket costs 40. It is 25% off. What do you pay?",
                answer: 30,
                check: "40 * 0.75",
                why: "25% off leaves 75%: 40 × 0.75 = 30.",
                hint: "Instead of finding the discount, find the fraction you still pay.",
                difficulty: .gentle
            ),
            .number(
                "math.percentages.2",
                lesson: "math.percentages",
                "12 is what percent of 48?",
                answer: 25,
                unit: "%",
                check: "12 / 48 * 100",
                why: "12 ÷ 48 = 0.25, and 0.25 × 100 = 25%.",
                hint: "Divide the part by the whole first."
            ),
            .choice(
                "math.percentages.3",
                lesson: "math.percentages",
                "A price rises 10%, then falls 10%. Compared with the start, the final price is:",
                options: ["The same", "Lower", "Higher", "Exactly double"],
                correct: 1,
                why: "1.10 × 0.90 = 0.99, so you end 1% below where you started. The fall is taken from a bigger number than the rise.",
                hint: "Try it on a price of 100 and multiply, step by step.",
                difficulty: .stretch
            ),
            .truth(
                "math.percentages.4",
                lesson: "math.percentages",
                "Adding 5 percentage points to a rate is the same as a 5% increase.",
                answer: false,
                why: "Going from 20% to 25% is 5 percentage points, but it is a 25% increase in the rate itself.",
                hint: "Ask what the 5% would be measured against."
            ),
            .match(
                "math.percentages.5",
                lesson: "math.percentages",
                "Match each fraction to its percentage.",
                pairs: [("1/4", "25%"), ("1/5", "20%"), ("3/4", "75%"), ("1/8", "12.5%")],
                why: "Divide top by bottom, then multiply by 100.",
                hint: "Start with the one you already know by heart."
            )
        ]
    )

    // MARK: - Solving for x

    static let solving = Lesson(
        id: "math.solving",
        title: "Solving for x",
        goal: "Undo an equation step by step and land on x.",
        facts: [
            "Whatever you do to one side of an equation, do to the other.",
            "Undo operations in reverse order: addition before multiplication.",
            "Multiplying out brackets is optional if you can divide first.",
            "Check an answer by substituting it back into the original equation."
        ],
        exercises: [
            .number(
                "math.solving.1",
                lesson: "math.solving",
                "Solve 3x + 7 = 22. What is x?",
                answer: 5,
                check: "(22 - 7) / 3",
                why: "Subtract 7 to get 3x = 15, then divide by 3 to get x = 5.",
                hint: "Get rid of the +7 before you touch the 3.",
                difficulty: .gentle
            ),
            .choice(
                "math.solving.2",
                lesson: "math.solving",
                "Solving 2x + 6 = 20, which move comes first?",
                options: [
                    "Divide both sides by 2",
                    "Subtract 6 from both sides",
                    "Add 6 to both sides",
                    "Multiply both sides by 2"
                ],
                correct: 1,
                why: "Peel operations off in reverse: the +6 is the outermost, so it goes first.",
                hint: "Think of unwrapping a parcel — outside layer first.",
                difficulty: .gentle
            ),
            .number(
                "math.solving.3",
                lesson: "math.solving",
                "Solve 5(x - 2) = 35. What is x?",
                answer: 9,
                check: "35 / 5 + 2",
                why: "Divide both sides by 5 to get x - 2 = 7, then add 2: x = 9.",
                hint: "Dividing by 5 first saves you expanding the bracket."
            ),
            .truth(
                "math.solving.4",
                lesson: "math.solving",
                "If 4x = 4y, then x = y.",
                answer: true,
                why: "Dividing both sides by 4 is allowed because 4 is not zero.",
                hint: "What single operation turns 4x into x?"
            ),
            .order(
                "math.solving.5",
                lesson: "math.solving",
                "Order the steps for solving 2x + 6 = 20.",
                steps: [
                    "Subtract 6 from both sides",
                    "Now 2x = 14",
                    "Divide both sides by 2",
                    "So x = 7"
                ],
                why: "Undo the addition, simplify, undo the multiplication, state the answer.",
                hint: "Each step should leave x a little more alone."
            )
        ]
    )

    // MARK: - Slope

    static let slope = Lesson(
        id: "math.slope",
        title: "Lines and slope",
        goal: "Read y = mx + b and get a line's steepness from two points.",
        facts: [
            "In y = mx + b, m is the slope and b is the y-intercept.",
            "Slope is rise over run: the change in y divided by the change in x.",
            "A horizontal line has slope 0; a vertical line has undefined slope.",
            "Parallel lines have equal slopes."
        ],
        exercises: [
            .number(
                "math.slope.1",
                lesson: "math.slope",
                "A line passes through (1, 2) and (4, 11). What is its slope?",
                answer: 3,
                check: "(11 - 2) / (4 - 1)",
                why: "Rise 11 - 2 = 9, run 4 - 1 = 3, so the slope is 9/3 = 3.",
                hint: "Rise over run — subtract in the same order top and bottom."
            ),
            .choice(
                "math.slope.2",
                lesson: "math.slope",
                "In y = mx + b, what does b tell you?",
                options: [
                    "How steep the line is",
                    "Where the line crosses the y-axis",
                    "Where the line crosses the x-axis",
                    "How long the line is"
                ],
                correct: 1,
                why: "Set x = 0 and you get y = b, which is the y-intercept.",
                hint: "Put x = 0 into the equation and see what survives.",
                difficulty: .gentle
            ),
            .number(
                "math.slope.3",
                lesson: "math.slope",
                "For y = -2x + 5, what is y when x = 3?",
                answer: -1,
                check: "-2 * 3 + 5",
                why: "-2 × 3 = -6, and -6 + 5 = -1.",
                hint: "Multiply before you add — and keep the minus sign."
            ),
            .truth(
                "math.slope.4",
                lesson: "math.slope",
                "A horizontal line has slope 0.",
                answer: true,
                why: "y never changes, so the rise is 0 and 0 divided by any run is 0.",
                hint: "How much does y climb as you walk along a flat line?"
            ),
            .text(
                "math.slope.5",
                lesson: "math.slope",
                "Two straight lines that never meet have the same ___.",
                accepted: ["slope", "gradient"],
                why: "Equal slopes means equal steepness, so the gap between the lines never closes.",
                hint: "It is the m in y = mx + b."
            )
        ]
    )
}
