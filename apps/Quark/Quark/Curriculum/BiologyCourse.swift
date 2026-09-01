//
//  BiologyCourse.swift
//  Quark
//
//  Curated biology content: cells, the path from DNA to protein, energy in
//  living things, and how selection actually works.
//

import Foundation

enum BiologyCourse {
    static let course = Course(
        track: .biology,
        units: [
            Unit(
                id: "biology.cells",
                title: "Cells and code",
                blurb: "The smallest unit of life, and the instructions inside it.",
                lessons: [cells, dna]
            ),
            Unit(
                id: "biology.life",
                title: "Energy and change",
                blurb: "How life pays its bills, and how it changes over time.",
                lessons: [energy, evolution]
            )
        ]
    )

    // MARK: - Cells

    static let cells = Lesson(
        id: "biology.cells",
        title: "The cell's toolkit",
        goal: "Name the main cell structures and say what each one does.",
        facts: [
            "The nucleus holds the cell's DNA.",
            "Mitochondria release energy from glucose in respiration.",
            "Ribosomes build proteins from amino acids.",
            "The cell membrane controls what enters and leaves.",
            "Plant cells have chloroplasts and a cell wall; animal cells do not.",
            "Bacteria are prokaryotes: they have no nucleus."
        ],
        exercises: [
            .match(
                "biology.cells.1",
                lesson: "biology.cells",
                "Match each structure to its job.",
                pairs: [
                    ("Nucleus", "Holds DNA"),
                    ("Mitochondrion", "Releases energy"),
                    ("Ribosome", "Builds proteins"),
                    ("Cell membrane", "Controls what enters")
                ],
                why: "Each structure is a specialised part, the way rooms in a workshop are.",
                hint: "Start with the one whose name you recognise from 'powerhouse'."
            ),
            .choice(
                "biology.cells.2",
                lesson: "biology.cells",
                "Which structure do plant cells have that animal cells do not?",
                options: ["Nucleus", "Chloroplast", "Ribosome", "Cell membrane"],
                correct: 1,
                why: "Chloroplasts do photosynthesis, which animals cannot do.",
                hint: "Which job can a plant do that you cannot?",
                difficulty: .gentle
            ),
            .truth(
                "biology.cells.3",
                lesson: "biology.cells",
                "Bacteria keep their DNA inside a nucleus.",
                answer: false,
                why: "Bacteria are prokaryotes — their DNA floats free in the cell with no nuclear membrane.",
                hint: "The word 'prokaryote' means 'before the nut'."
            ),
            .text(
                "biology.cells.4",
                lesson: "biology.cells",
                "What is the name of the cell division that produces two identical cells?",
                accepted: ["mitosis"],
                why: "Mitosis copies a cell. Meiosis, by contrast, halves the chromosome number for sex cells.",
                hint: "It is not meiosis."
            ),
            .number(
                "biology.cells.5",
                lesson: "biology.cells",
                "One cell divides by mitosis three times. How many cells are there now?",
                answer: 8,
                check: "2^3",
                why: "Each round doubles the count: 1 → 2 → 4 → 8.",
                hint: "Doubling three times is 2 × 2 × 2."
            )
        ]
    )

    // MARK: - DNA

    static let dna = Lesson(
        id: "biology.dna",
        title: "DNA to protein",
        goal: "Follow the central dogma and use base pairing.",
        facts: [
            "DNA bases pair A with T and C with G.",
            "RNA uses uracil in place of thymine.",
            "Transcription copies DNA into mRNA; translation builds a protein from mRNA.",
            "A gene is a stretch of DNA that codes for a protein."
        ],
        exercises: [
            .choice(
                "biology.dna.1",
                lesson: "biology.dna",
                "In DNA, the bases pair up as:",
                options: ["A–G and C–T", "A–T and C–G", "A–C and G–T", "Any base with any base"],
                correct: 1,
                why: "A pairs with T, C pairs with G. That is what makes DNA copyable.",
                hint: "The two pairs each contain one letter from the start of the alphabet.",
                difficulty: .gentle
            ),
            .order(
                "biology.dna.2",
                lesson: "biology.dna",
                "Order the steps from gene to protein.",
                steps: ["DNA", "Transcription", "mRNA", "Translation", "Protein"],
                why: "The central dogma: DNA is transcribed to mRNA, which is translated into protein.",
                hint: "Transcribing comes before translating, in biology as in language."
            ),
            .truth(
                "biology.dna.3",
                lesson: "biology.dna",
                "RNA uses uracil where DNA uses thymine.",
                answer: true,
                why: "U replaces T in RNA; the other three bases are shared.",
                hint: "Only one of the four letters changes.",
                difficulty: .gentle
            ),
            .number(
                "biology.dna.4",
                lesson: "biology.dna",
                "A double-stranded DNA sample is 30% adenine. What percentage is thymine?",
                answer: 30,
                unit: "%",
                check: "30",
                why: "A always pairs with T, so their percentages match. That leaves 20% each for C and G.",
                hint: "Base pairing forces the two to be equal.",
                difficulty: .stretch
            ),
            .text(
                "biology.dna.5",
                lesson: "biology.dna",
                "A stretch of DNA that codes for one protein is called a ___.",
                accepted: ["gene"],
                why: "Genes are the functional units of the genome.",
                hint: "Four letters, and it is what you inherit."
            )
        ]
    )

    // MARK: - Energy

    static let energy = Lesson(
        id: "biology.energy",
        title: "Energy in living things",
        goal: "Compare photosynthesis and respiration as two halves of one cycle.",
        facts: [
            "Photosynthesis uses light to turn carbon dioxide and water into glucose and oxygen.",
            "Respiration uses oxygen to release energy from glucose, producing carbon dioxide and water.",
            "Chlorophyll absorbs the light that powers photosynthesis.",
            "Plants respire all the time, and photosynthesise only in light."
        ],
        exercises: [
            .choice(
                "biology.energy.1",
                lesson: "biology.energy",
                "Photosynthesis converts light energy into:",
                options: [
                    "Heat and nothing else",
                    "Chemical energy stored in glucose",
                    "Oxygen and nothing else",
                    "Movement"
                ],
                correct: 1,
                why: "The oxygen is a by-product; the point is the sugar, which stores the energy.",
                hint: "Ask what the plant keeps at the end.",
                difficulty: .gentle
            ),
            .match(
                "biology.energy.2",
                lesson: "biology.energy",
                "Match each term to its description.",
                pairs: [
                    ("Photosynthesis", "Takes in CO₂, gives out O₂"),
                    ("Respiration", "Takes in O₂, gives out CO₂"),
                    ("Chlorophyll", "Absorbs light"),
                    ("Glucose", "Stores the energy")
                ],
                why: "The two processes run in opposite directions, which is why the cycle closes.",
                hint: "Two of these are processes and two are substances."
            ),
            .truth(
                "biology.energy.3",
                lesson: "biology.energy",
                "Plants respire as well as photosynthesise.",
                answer: true,
                why: "Every living cell respires. Photosynthesis is the extra trick plants have.",
                hint: "How does a plant get energy at night?"
            ),
            .text(
                "biology.energy.4",
                lesson: "biology.energy",
                "Which gas do plants take in for photosynthesis?",
                accepted: ["carbon dioxide", "co2"],
                why: "Carbon dioxide supplies the carbon that ends up in glucose.",
                hint: "It is the gas you breathe out.",
                difficulty: .gentle
            ),
            .order(
                "biology.energy.5",
                lesson: "biology.energy",
                "Order the stages of photosynthesis.",
                steps: [
                    "Light hits chlorophyll",
                    "Water molecules split",
                    "Carbon dioxide is captured",
                    "Glucose is assembled"
                ],
                why: "Light first supplies the energy, then the carbon is fixed into sugar.",
                hint: "Nothing happens until the energy arrives."
            )
        ]
    )

    // MARK: - Evolution

    static let evolution = Lesson(
        id: "biology.evolution",
        title: "How selection works",
        goal: "State natural selection precisely enough to use it.",
        facts: [
            "Natural selection acts on inherited variation that already exists.",
            "Populations evolve; individual organisms do not evolve during their lives.",
            "Homologous structures share a common ancestry.",
            "Antibiotic resistance spreads because resistant bacteria survive and reproduce."
        ],
        exercises: [
            .choice(
                "biology.evolution.1",
                lesson: "biology.evolution",
                "Natural selection acts on:",
                options: [
                    "What an individual wants",
                    "Inherited variation already present in the population",
                    "Luck alone, with no pattern",
                    "Traits acquired during a lifetime"
                ],
                correct: 1,
                why: "Selection can only sort variation that exists and can be passed on.",
                hint: "Selection sorts; it does not design."
            ),
            .truth(
                "biology.evolution.2",
                lesson: "biology.evolution",
                "An individual organism evolves over the course of its life.",
                answer: false,
                why: "Individuals develop and adapt physiologically. Evolution is a change in a population across generations.",
                hint: "What is the unit that changes between generations?"
            ),
            .text(
                "biology.evolution.3",
                lesson: "biology.evolution",
                "A bat's wing and a human arm share the same underlying bone plan. Such structures are called ___.",
                accepted: ["homologous", "homologous structures"],
                why: "Homologous structures point to a shared ancestor, even when the jobs differ.",
                hint: "The word starts with 'homo', meaning same.",
                difficulty: .stretch
            ),
            .number(
                "biology.evolution.4",
                lesson: "biology.evolution",
                "A population of 100 bacteria doubles each generation. How many are there after 4 generations?",
                answer: 1600,
                check: "100 * 2^4",
                why: "100 × 2⁴ = 100 × 16 = 1600.",
                hint: "Doubling four times multiplies by 16."
            ),
            .choice(
                "biology.evolution.5",
                lesson: "biology.evolution",
                "Antibiotic resistance spreads through a bacterial population because:",
                options: [
                    "Bacteria decide to resist the drug",
                    "Resistant bacteria survive and reproduce",
                    "Antibiotics create resistance genes",
                    "Resistance is passed on by contact with the drug"
                ],
                correct: 1,
                why: "The drug removes the susceptible bacteria, leaving the resistant ones to fill the space.",
                hint: "The mutation is there before the drug arrives."
            )
        ]
    )
}
