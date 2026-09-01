//
//  ChemistryCourse.swift
//  Quark
//
//  Curated chemistry content: what an atom is made of, how the table is
//  organised, counting by moles, and the pH scale.
//

import Foundation

enum ChemistryCourse {
    static let course = Course(
        track: .chemistry,
        units: [
            Unit(
                id: "chemistry.atoms",
                title: "Atoms and the table",
                blurb: "What stuff is made of, and how it is filed.",
                lessons: [atoms, periodicTable]
            ),
            Unit(
                id: "chemistry.reactions",
                title: "Reactions",
                blurb: "Counting particles and measuring acidity.",
                lessons: [moles, acids]
            )
        ]
    )

    // MARK: - Atoms

    static let atoms = Lesson(
        id: "chemistry.atoms",
        title: "Inside the atom",
        goal: "Name the particles in an atom and count them from a symbol.",
        facts: [
            "Protons are positive, electrons are negative, and neutrons have no charge.",
            "The number of protons is the atomic number and fixes which element it is.",
            "A neutral atom has equal numbers of protons and electrons.",
            "Mass number minus atomic number gives the neutron count.",
            "Isotopes of an element have the same protons but different neutrons."
        ],
        exercises: [
            .number(
                "chemistry.atoms.1",
                lesson: "chemistry.atoms",
                "A neutral atom has 11 protons. How many electrons does it have?",
                answer: 11,
                check: "11",
                why: "Neutral means the charges cancel, so electrons equal protons.",
                hint: "What has to be true for the total charge to be zero?",
                difficulty: .gentle
            ),
            .choice(
                "chemistry.atoms.2",
                lesson: "chemistry.atoms",
                "What decides which element an atom is?",
                options: [
                    "Its number of neutrons",
                    "Its number of protons",
                    "Its number of electrons",
                    "Its mass in grams"
                ],
                correct: 1,
                why: "The proton count is the atomic number, and that is the element's identity.",
                hint: "It is the number the periodic table is sorted by.",
                difficulty: .gentle
            ),
            .number(
                "chemistry.atoms.3",
                lesson: "chemistry.atoms",
                "Carbon-14 has 6 protons. How many neutrons does it have?",
                answer: 8,
                check: "14 - 6",
                why: "Mass number 14 minus 6 protons leaves 8 neutrons.",
                hint: "The number in the name is protons plus neutrons."
            ),
            .truth(
                "chemistry.atoms.4",
                lesson: "chemistry.atoms",
                "Isotopes of an element differ in their number of neutrons.",
                answer: true,
                why: "Same protons, different neutrons — same chemistry, different mass.",
                hint: "If protons changed, it would be a different element."
            ),
            .match(
                "chemistry.atoms.5",
                lesson: "chemistry.atoms",
                "Match each part of the atom to its description.",
                pairs: [
                    ("Proton", "Positive charge"),
                    ("Neutron", "No charge"),
                    ("Electron", "Negative charge"),
                    ("Nucleus", "Protons and neutrons")
                ],
                why: "The nucleus holds protons and neutrons; electrons occupy the space around it.",
                hint: "Two of the four names tell you their charge outright."
            )
        ]
    )

    // MARK: - Periodic table

    static let periodicTable = Lesson(
        id: "chemistry.table",
        title: "Reading the periodic table",
        goal: "Use groups and periods to predict how an element behaves.",
        facts: [
            "A group is a column; elements in a group have similar outer-electron counts.",
            "A period is a row; the modern table has 7 periods.",
            "Noble gases are unreactive because their outer shell is already full.",
            "Elements are ordered left to right by increasing atomic number."
        ],
        exercises: [
            .choice(
                "chemistry.table.1",
                lesson: "chemistry.table",
                "Elements in the same group of the periodic table share:",
                options: [
                    "The same mass",
                    "A similar number of outer electrons",
                    "The same state at room temperature",
                    "The same number of neutrons"
                ],
                correct: 1,
                why: "Outer electrons drive bonding, which is why a group behaves as a family.",
                hint: "Chemistry is mostly decided by the outermost electrons."
            ),
            .text(
                "chemistry.table.2",
                lesson: "chemistry.table",
                "What is the chemical symbol for sodium?",
                accepted: ["Na"],
                why: "Sodium's symbol comes from its Latin name, natrium.",
                hint: "It is two letters, and neither of them is S.",
                difficulty: .gentle
            ),
            .truth(
                "chemistry.table.3",
                lesson: "chemistry.table",
                "Noble gases are unreactive because their outer electron shell is full.",
                answer: true,
                why: "With nothing to gain from bonding, they mostly keep to themselves.",
                hint: "Reactivity is about wanting to gain, lose, or share electrons.",
                difficulty: .gentle
            ),
            .number(
                "chemistry.table.4",
                lesson: "chemistry.table",
                "How many periods, or rows, does the modern periodic table have?",
                answer: 7,
                check: "7",
                why: "Seven periods, matching the electron shells being filled.",
                hint: "Count the rows in the main block."
            ),
            .order(
                "chemistry.table.5",
                lesson: "chemistry.table",
                "Order these elements by increasing atomic number.",
                steps: ["Hydrogen", "Helium", "Lithium", "Beryllium"],
                why: "Atomic numbers 1, 2, 3, and 4 — the first four elements in order.",
                hint: "Start at the top-left corner of the table and read across."
            )
        ]
    )

    // MARK: - Moles

    static let moles = Lesson(
        id: "chemistry.moles",
        title: "Moles and balancing",
        goal: "Convert between grams and moles, and balance a simple equation.",
        facts: [
            "A mole is 6.02 × 10²³ particles — Avogadro's number.",
            "Moles equal mass in grams divided by molar mass in grams per mole.",
            "Balancing an equation conserves the atoms of every element.",
            "A catalyst speeds a reaction up without being consumed."
        ],
        exercises: [
            .number(
                "chemistry.moles.1",
                lesson: "chemistry.moles",
                "One mole of carbon weighs 12 g. What do 3 moles weigh?",
                answer: 36,
                unit: "g",
                check: "12 * 3",
                why: "12 g per mole × 3 moles = 36 g.",
                hint: "Multiply the mass of one mole by the number of moles.",
                difficulty: .gentle
            ),
            .number(
                "chemistry.moles.2",
                lesson: "chemistry.moles",
                "How many moles are in 24 g of carbon, at 12 g per mole?",
                answer: 2,
                unit: "mol",
                check: "24 / 12",
                why: "Moles = mass ÷ molar mass = 24 ÷ 12 = 2 mol.",
                hint: "This is the previous question run backwards."
            ),
            .choice(
                "chemistry.moles.3",
                lesson: "chemistry.moles",
                "Balancing a chemical equation makes sure you conserve:",
                options: [
                    "The atoms of each element",
                    "The number of molecules",
                    "The volume of gas",
                    "The temperature"
                ],
                correct: 0,
                why: "Atoms are neither created nor destroyed, so each element must balance on both sides.",
                hint: "Count one element at a time on each side."
            ),
            .text(
                "chemistry.moles.4",
                lesson: "chemistry.moles",
                "Balance H₂ + O₂ → H₂O. What coefficient belongs in front of H₂O?",
                accepted: ["2", "two"],
                why: "2H₂ + O₂ → 2H₂O: four hydrogens and two oxygens on each side.",
                hint: "Start with oxygen and count how many atoms sit on each side.",
                difficulty: .stretch
            ),
            .truth(
                "chemistry.moles.5",
                lesson: "chemistry.moles",
                "A catalyst is used up during the reaction it speeds up.",
                answer: false,
                why: "A catalyst lowers the energy barrier and comes out the other side unchanged.",
                hint: "If it were consumed, you would have to keep buying more."
            )
        ]
    )

    // MARK: - Acids

    static let acids = Lesson(
        id: "chemistry.acids",
        title: "Acids and bases",
        goal: "Read the pH scale and know what each step on it means.",
        facts: [
            "The pH scale runs from 0 to 14; below 7 is acidic and above 7 is basic.",
            "Pure water at 25 °C has a pH of 7.",
            "Each pH step is a factor of ten in hydrogen-ion concentration.",
            "An indicator such as litmus changes colour with pH."
        ],
        exercises: [
            .choice(
                "chemistry.acids.1",
                lesson: "chemistry.acids",
                "A solution with pH 3 is:",
                options: ["Basic", "Neutral", "Acidic", "Off the scale"],
                correct: 2,
                why: "Anything below 7 is acidic, and 3 is well below.",
                hint: "Neutral sits at 7 — which side of it is 3?",
                difficulty: .gentle
            ),
            .number(
                "chemistry.acids.2",
                lesson: "chemistry.acids",
                "How many times more hydrogen ions does pH 4 have than pH 6?",
                answer: 100,
                check: "10^2",
                why: "Two pH steps, each a factor of ten: 10 × 10 = 100 times more.",
                hint: "The scale is logarithmic, so steps multiply.",
                difficulty: .stretch
            ),
            .truth(
                "chemistry.acids.3",
                lesson: "chemistry.acids",
                "Pure water at 25 °C has a pH of 7.",
                answer: true,
                why: "It is the definition of neutral: equal hydrogen and hydroxide ions.",
                hint: "It is the number in the middle of the scale.",
                difficulty: .gentle
            ),
            .number(
                "chemistry.acids.4",
                lesson: "chemistry.acids",
                "The pH scale runs from 0 up to what number?",
                answer: 14,
                check: "14",
                why: "0 to 14, with 7 as neutral in the middle.",
                hint: "Double the neutral value."
            ),
            .match(
                "chemistry.acids.5",
                lesson: "chemistry.acids",
                "Match each reading to what it describes.",
                pairs: [
                    ("pH 1", "Strong acid"),
                    ("pH 7", "Neutral"),
                    ("pH 13", "Strong base"),
                    ("Litmus", "Indicator")
                ],
                why: "Low is acidic, high is basic, and an indicator is the tool that tells you which.",
                hint: "Three of these are numbers on the same scale."
            )
        ]
    )
}
