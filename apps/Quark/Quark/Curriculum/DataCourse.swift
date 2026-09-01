//
//  DataCourse.swift
//  Quark
//
//  Curated data and statistics content: describing a data set, reading a
//  chart honestly, basic probability, and the difference between a
//  correlation and a cause.
//

import Foundation

enum DataCourse {
    static let course = Course(
        track: .data,
        units: [
            Unit(
                id: "data.describing",
                title: "Describing data",
                blurb: "Centre, spread, and charts that tell the truth.",
                lessons: [centre, charts]
            ),
            Unit(
                id: "data.uncertainty",
                title: "Reasoning under uncertainty",
                blurb: "Probability, and the trap of the obvious explanation.",
                lessons: [probability, causation]
            )
        ]
    )

    // MARK: - Centre and spread

    static let centre = Lesson(
        id: "data.centre",
        title: "Mean, median, spread",
        goal: "Compute the centre of a data set and know which measure to trust.",
        facts: [
            "The mean is the total divided by the count.",
            "The median is the middle value once the data is sorted; with an even count, average the middle two.",
            "The mode is the most common value.",
            "Outliers pull the mean much more than the median.",
            "Standard deviation measures spread, not centre."
        ],
        exercises: [
            .number(
                "data.centre.1",
                lesson: "data.centre",
                "What is the mean of 4, 8, 10, 10, and 18?",
                answer: 10,
                check: "(4 + 8 + 10 + 10 + 18) / 5",
                why: "The total is 50, and 50 ÷ 5 = 10.",
                hint: "Add them all, then divide by how many there are.",
                difficulty: .gentle
            ),
            .number(
                "data.centre.2",
                lesson: "data.centre",
                "What is the median of 3, 7, 9, and 21?",
                answer: 8,
                check: "(7 + 9) / 2",
                why: "With four values there is no single middle, so average the middle two: (7 + 9) ÷ 2 = 8.",
                hint: "An even count needs the average of two values."
            ),
            .choice(
                "data.centre.3",
                lesson: "data.centre",
                "One billionaire joins a room of 50 teachers. Which measure of income changes most?",
                options: ["The median", "The mean", "Both change equally", "Neither changes"],
                correct: 1,
                why: "The mean adds the whole outlier to the total. The median only shifts by one position in the sorted list.",
                hint: "Which measure uses every value's actual size?",
                difficulty: .stretch
            ),
            .truth(
                "data.centre.4",
                lesson: "data.centre",
                "Standard deviation tells you about spread rather than centre.",
                answer: true,
                why: "It measures the typical distance from the mean, so two data sets with the same mean can have very different deviations.",
                hint: "Could two very different data sets share a mean?"
            ),
            .text(
                "data.centre.5",
                lesson: "data.centre",
                "The most frequently occurring value in a data set is the ___.",
                accepted: ["mode"],
                why: "Mode is the only one of the three averages that works on categories as well as numbers.",
                hint: "It is four letters and starts with M.",
                difficulty: .gentle
            )
        ]
    )

    // MARK: - Charts

    static let charts = Lesson(
        id: "data.charts",
        title: "Charts that don't lie",
        goal: "Pick the right chart, and spot one that is misleading you.",
        facts: [
            "A truncated y-axis exaggerates differences.",
            "A histogram shows the distribution of one variable.",
            "A scatter plot shows the relationship between two variables.",
            "A line chart shows change over time; a box plot shows spread and outliers.",
            "Pie charts become unreadable past about five slices."
        ],
        exercises: [
            .choice(
                "data.charts.1",
                lesson: "data.charts",
                "A bar chart whose y-axis starts at 90 instead of 0 tends to:",
                options: [
                    "Hide real differences",
                    "Exaggerate small differences",
                    "Change nothing at all",
                    "Remove outliers"
                ],
                correct: 1,
                why: "Cutting off the bottom of the bars makes a 2% gap look like a landslide.",
                hint: "Picture the bars with the bottom 90% chopped away."
            ),
            .truth(
                "data.charts.2",
                lesson: "data.charts",
                "A pie chart is a good way to compare fifteen categories.",
                answer: false,
                why: "Fifteen slices are impossible to compare by angle. A sorted bar chart does the job.",
                hint: "Try to rank three slices of similar size by eye.",
                difficulty: .gentle
            ),
            .match(
                "data.charts.3",
                lesson: "data.charts",
                "Match each chart to the question it answers.",
                pairs: [
                    ("Histogram", "How is one variable distributed?"),
                    ("Scatter plot", "Are two variables related?"),
                    ("Line chart", "How has this changed over time?"),
                    ("Box plot", "Where are the spread and outliers?")
                ],
                why: "Choose the chart from the question, not the other way round.",
                hint: "Only one of these has time on an axis by convention."
            ),
            .order(
                "data.charts.4",
                lesson: "data.charts",
                "Order the steps for making an honest chart.",
                steps: [
                    "Write down the question",
                    "Choose the variables that answer it",
                    "Pick the chart type that fits",
                    "Label the axes and state the units"
                ],
                why: "The question decides the variables, the variables decide the chart, and labels make it checkable.",
                hint: "Design decisions come after you know what you are asking."
            ),
            .text(
                "data.charts.5",
                lesson: "data.charts",
                "A single value that sits far away from the rest of the data is an ___.",
                accepted: ["outlier"],
                why: "Outliers deserve investigation: sometimes an error, sometimes the most interesting point on the chart.",
                hint: "It lies outside the pack."
            )
        ]
    )

    // MARK: - Probability

    static let probability = Lesson(
        id: "data.probability",
        title: "Probability basics",
        goal: "Compute simple probabilities and avoid the classic traps.",
        facts: [
            "Probability of an event is favourable outcomes divided by total equally likely outcomes.",
            "Independent events multiply: two fair coins give 1/2 × 1/2 = 1/4 for two heads.",
            "The probability of an event not happening is 1 minus its probability.",
            "Coins have no memory, so past flips do not change the next one.",
            "For a rare condition, most positive results from an imperfect test are false positives."
        ],
        exercises: [
            .number(
                "data.probability.1",
                lesson: "data.probability",
                "Flip two fair coins. What is the probability of two heads? Give a decimal.",
                answer: 0.25,
                tolerance: 0.005,
                check: "1 / 4",
                why: "Four equally likely outcomes: HH, HT, TH, TT. Only one is two heads.",
                hint: "List every possible pair of results.",
                difficulty: .gentle
            ),
            .number(
                "data.probability.2",
                lesson: "data.probability",
                "Roll one fair die. What is the probability of a number greater than 4? Give a decimal.",
                answer: 0.3333,
                tolerance: 0.006,
                check: "2 / 6",
                why: "Only 5 and 6 qualify, so 2 out of 6, which is about 0.33.",
                hint: "Count how many faces beat 4."
            ),
            .truth(
                "data.probability.3",
                lesson: "data.probability",
                "After five heads in a row, a fair coin is more likely to land tails next.",
                answer: false,
                why: "This is the gambler's fallacy. The coin has no memory: it is still 1/2.",
                hint: "Does the coin know what it did last time?"
            ),
            .choice(
                "data.probability.4",
                lesson: "data.probability",
                "A test is 99% accurate for a condition that 1 person in 10,000 has. You test positive. Most likely:",
                options: [
                    "You almost certainly have the condition",
                    "It is still far more likely to be a false positive",
                    "The test must be broken",
                    "There is no way to reason about it"
                ],
                correct: 1,
                why: "Out of a million people, about 100 have it, while roughly 10,000 healthy people test positive anyway. The base rate dominates.",
                hint: "Imagine testing a million people and count both groups.",
                difficulty: .stretch
            ),
            .number(
                "data.probability.5",
                lesson: "data.probability",
                "What is the probability of not rolling a 6 on one fair die? Give a decimal.",
                answer: 0.8333,
                tolerance: 0.006,
                check: "5 / 6",
                why: "Five of the six faces are not a 6, so 5/6 ≈ 0.83.",
                hint: "Take 1 and subtract the chance of rolling a 6."
            )
        ]
    )

    // MARK: - Causation

    static let causation = Lesson(
        id: "data.causation",
        title: "Correlation and cause",
        goal: "Say what a correlation does and does not license you to claim.",
        facts: [
            "Correlation measures how two variables move together, from -1 to +1.",
            "The strength of a correlation is its distance from zero, so -0.9 is stronger than +0.3.",
            "A confounding variable can explain both variables at once.",
            "A randomised controlled experiment is the cleanest evidence for cause."
        ],
        exercises: [
            .choice(
                "data.causation.1",
                lesson: "data.causation",
                "Ice cream sales and drowning deaths both rise in summer. This is best described as:",
                options: [
                    "Ice cream causing drowning",
                    "A correlation explained by a third factor",
                    "A measurement error",
                    "A statistical impossibility"
                ],
                correct: 1,
                why: "Hot weather drives both. That shared cause is the confounder.",
                hint: "What else changes in summer?",
                difficulty: .gentle
            ),
            .truth(
                "data.causation.2",
                lesson: "data.causation",
                "A correlation of -0.9 is weaker than a correlation of +0.3.",
                answer: false,
                why: "The sign gives the direction, not the strength. -0.9 is a much tighter relationship.",
                hint: "Look at the distance from zero, not the sign."
            ),
            .text(
                "data.causation.3",
                lesson: "data.causation",
                "A hidden third factor that explains both variables is called a ___ variable.",
                accepted: ["confounding", "confounder", "confound"],
                why: "Naming the confounder is usually the whole job in reading a study.",
                hint: "It shares a root with 'confuse'.",
                difficulty: .stretch
            ),
            .choice(
                "data.causation.4",
                lesson: "data.causation",
                "The cleanest way to establish that A causes B is:",
                options: [
                    "A larger survey",
                    "A randomised controlled experiment",
                    "A clearer chart",
                    "More correlations pointing the same way"
                ],
                correct: 1,
                why: "Randomising who gets the treatment breaks the link with every confounder at once.",
                hint: "Which option changes A on purpose rather than observing it?"
            ),
            .number(
                "data.causation.5",
                lesson: "data.causation",
                "A correlation coefficient runs from -1 up to what value?",
                answer: 1,
                check: "1",
                why: "+1 is a perfect positive relationship, -1 a perfect negative one, and 0 none at all.",
                hint: "The scale is symmetric around zero.",
                difficulty: .gentle
            )
        ]
    )
}
