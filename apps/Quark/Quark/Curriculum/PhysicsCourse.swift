//
//  PhysicsCourse.swift
//  Quark
//
//  Curated physics content: motion, forces, energy, and waves, kept to the
//  quantities a learner can reason about with one equation at a time.
//

import Foundation

enum PhysicsCourse {
    static let course = Course(
        track: .physics,
        units: [
            Unit(
                id: "physics.motion",
                title: "Motion",
                blurb: "Describe movement, then explain it.",
                lessons: [kinematics, forces]
            ),
            Unit(
                id: "physics.energy",
                title: "Energy and waves",
                blurb: "What gets carried, and how.",
                lessons: [energy, waves]
            )
        ]
    )

    // MARK: - Kinematics

    static let kinematics = Lesson(
        id: "physics.kinematics",
        title: "Speed, velocity, acceleration",
        goal: "Tell these three apart and compute each one.",
        facts: [
            "Average speed is distance divided by time.",
            "Velocity is speed with a direction, which makes it a vector.",
            "Acceleration is the change in velocity divided by time.",
            "Changing direction is acceleration even at constant speed."
        ],
        exercises: [
            .number(
                "physics.kinematics.1",
                lesson: "physics.kinematics",
                "A train covers 240 km in 3 hours. What is its average speed?",
                answer: 80,
                unit: "km/h",
                check: "240 / 3",
                why: "Speed is distance over time: 240 ÷ 3 = 80 km/h.",
                hint: "Divide the distance by the time.",
                difficulty: .gentle
            ),
            .choice(
                "physics.kinematics.2",
                lesson: "physics.kinematics",
                "Which of these is a vector?",
                options: ["Speed", "Distance", "Velocity", "Time"],
                correct: 2,
                why: "Velocity carries a direction as well as a size. The other three are scalars.",
                hint: "Which one changes if you turn around but keep going the same rate?",
                difficulty: .gentle
            ),
            .number(
                "physics.kinematics.3",
                lesson: "physics.kinematics",
                "A car goes from 0 to 30 m/s in 6 s. What is its acceleration?",
                answer: 5,
                unit: "m/s²",
                check: "30 / 6",
                why: "Change in velocity ÷ time = 30 ÷ 6 = 5 m/s².",
                hint: "How much velocity is gained each second?"
            ),
            .truth(
                "physics.kinematics.4",
                lesson: "physics.kinematics",
                "An object moving at a constant speed around a circle has zero acceleration.",
                answer: false,
                why: "Its direction keeps changing, so its velocity changes — that is acceleration, pointing towards the centre.",
                hint: "Acceleration is about velocity, and velocity includes direction.",
                difficulty: .stretch
            ),
            .order(
                "physics.kinematics.5",
                lesson: "physics.kinematics",
                "Order these ideas by how they build on each other.",
                steps: ["Position", "Displacement", "Velocity", "Acceleration"],
                why: "Displacement is a change in position, velocity is displacement per time, and acceleration is a change in velocity.",
                hint: "Each one is the rate of change of the one before it."
            )
        ]
    )

    // MARK: - Forces

    static let forces = Lesson(
        id: "physics.forces",
        title: "Forces and Newton",
        goal: "Use F = ma and read a situation in terms of Newton's laws.",
        facts: [
            "Newton's first law: without a net force, motion does not change.",
            "Newton's second law: net force equals mass times acceleration.",
            "Newton's third law: forces come in equal and opposite pairs.",
            "Weight is mass times gravitational field strength, about 9.8 N per kg on Earth."
        ],
        exercises: [
            .number(
                "physics.forces.1",
                lesson: "physics.forces",
                "A 4 kg mass accelerates at 3 m/s². What net force acts on it?",
                answer: 12,
                unit: "N",
                check: "4 * 3",
                why: "F = ma = 4 × 3 = 12 N.",
                hint: "Multiply the mass by the acceleration.",
                difficulty: .gentle
            ),
            .choice(
                "physics.forces.2",
                lesson: "physics.forces",
                "You push a wall and it does not move. Newton's third law says:",
                options: [
                    "The wall pushes back on you with an equal force",
                    "No forces are acting",
                    "The wall's push is smaller than yours",
                    "Your force disappears into the wall"
                ],
                correct: 0,
                why: "Forces always come in pairs. The wall does not move because it is held in place, not because it pushes less.",
                hint: "Third-law pairs are equal in size and opposite in direction."
            ),
            .truth(
                "physics.forces.3",
                lesson: "physics.forces",
                "An object sitting still has no forces acting on it.",
                answer: false,
                why: "A book on a table has gravity pulling down and the table pushing up. They cancel, so the net force is zero.",
                hint: "Zero net force is not the same as zero forces."
            ),
            .number(
                "physics.forces.4",
                lesson: "physics.forces",
                "What is the weight of a 10 kg bag on Earth, taking g as 9.8 N/kg?",
                answer: 98,
                unit: "N",
                check: "10 * 9.8",
                why: "Weight = mass × g = 10 × 9.8 = 98 N. Mass is in kilograms; weight is a force in newtons.",
                hint: "Weight is a force, so it should come out in newtons."
            ),
            .match(
                "physics.forces.5",
                lesson: "physics.forces",
                "Match each law or idea to its summary.",
                pairs: [
                    ("First law", "Inertia"),
                    ("Second law", "F = ma"),
                    ("Third law", "Equal and opposite"),
                    ("Friction", "Opposes sliding")
                ],
                why: "The three laws describe unchanged motion, forced motion, and force pairs. Friction is a specific contact force.",
                hint: "Start with the one that has an equation attached."
            )
        ]
    )

    // MARK: - Energy

    static let energy = Lesson(
        id: "physics.energy",
        title: "Energy and work",
        goal: "Track energy as it moves between stores, and compute the easy cases.",
        facts: [
            "Energy is conserved: it moves between stores rather than appearing or vanishing.",
            "Gravitational potential energy gained is mass times g times height.",
            "Kinetic energy is one half times mass times velocity squared.",
            "Power is energy per second, so energy equals power times time."
        ],
        exercises: [
            .number(
                "physics.energy.1",
                lesson: "physics.energy",
                "You lift a 2 kg book 1.5 m. How much gravitational potential energy does it gain? Take g as 9.8.",
                answer: 29.4,
                tolerance: 0.2,
                unit: "J",
                check: "2 * 9.8 * 1.5",
                why: "mgh = 2 × 9.8 × 1.5 = 29.4 J.",
                hint: "Multiply mass, g, and height together."
            ),
            .choice(
                "physics.energy.2",
                lesson: "physics.energy",
                "Kinetic energy exactly doubles when:",
                options: [
                    "Speed doubles",
                    "Mass doubles",
                    "Height doubles",
                    "Time doubles"
                ],
                correct: 1,
                why: "KE = ½mv². Mass appears once, so doubling it doubles the energy. Doubling the speed quadruples it.",
                hint: "Look at which quantity is squared in the formula.",
                difficulty: .stretch
            ),
            .truth(
                "physics.energy.3",
                lesson: "physics.energy",
                "With enough force, energy can be created from nothing.",
                answer: false,
                why: "Energy is conserved. A force can transfer energy between stores, but it cannot make more of it.",
                hint: "Force and energy are different quantities.",
                difficulty: .gentle
            ),
            .number(
                "physics.energy.4",
                lesson: "physics.energy",
                "A 60 W bulb runs for 120 s. How much energy does it use?",
                answer: 7200,
                unit: "J",
                check: "60 * 120",
                why: "Energy = power × time = 60 × 120 = 7200 J.",
                hint: "A watt is a joule per second."
            ),
            .text(
                "physics.energy.5",
                lesson: "physics.energy",
                "Energy is never created or destroyed — physicists say it is ___.",
                accepted: ["conserved", "conservation"],
                why: "Conservation of energy is one of the load-bearing rules of physics.",
                hint: "The word also names the law itself.",
                difficulty: .gentle
            )
        ]
    )

    // MARK: - Waves

    static let waves = Lesson(
        id: "physics.waves",
        title: "Waves and light",
        goal: "Relate speed, frequency, and wavelength, and place light on the spectrum.",
        facts: [
            "Wave speed equals frequency times wavelength.",
            "Higher frequency means shorter wavelength at a fixed speed.",
            "Sound needs a medium; light does not.",
            "Light travels at about 3 × 10⁸ m/s in a vacuum."
        ],
        exercises: [
            .number(
                "physics.waves.1",
                lesson: "physics.waves",
                "A wave has a frequency of 5 Hz and a wavelength of 4 m. How fast does it travel?",
                answer: 20,
                unit: "m/s",
                check: "5 * 4",
                why: "v = fλ = 5 × 4 = 20 m/s.",
                hint: "Multiply the two numbers you are given.",
                difficulty: .gentle
            ),
            .choice(
                "physics.waves.2",
                lesson: "physics.waves",
                "At a fixed speed, light with a higher frequency has:",
                options: [
                    "A longer wavelength",
                    "A shorter wavelength",
                    "The same wavelength",
                    "No wavelength"
                ],
                correct: 1,
                why: "Since v = fλ and v is fixed, raising f must lower λ.",
                hint: "If the product stays the same, what happens to the other factor?"
            ),
            .truth(
                "physics.waves.3",
                lesson: "physics.waves",
                "Sound can travel through a vacuum.",
                answer: false,
                why: "Sound is a pressure wave and needs particles to squeeze. Light, being electromagnetic, needs nothing.",
                hint: "What exactly is vibrating when sound travels?",
                difficulty: .gentle
            ),
            .number(
                "physics.waves.4",
                lesson: "physics.waves",
                "Light travels at 3 × 10⁸ m/s. How many seconds does it take to cross 3 × 10⁹ m?",
                answer: 10,
                unit: "s",
                check: "3 * 10^9 / (3 * 10^8)",
                why: "Distance ÷ speed = (3 × 10⁹) ÷ (3 × 10⁸) = 10 s.",
                hint: "Divide the powers of ten and the coefficients separately.",
                difficulty: .stretch
            ),
            .order(
                "physics.waves.5",
                lesson: "physics.waves",
                "Order these by increasing wavelength.",
                steps: ["Gamma rays", "X-rays", "Visible light", "Radio waves"],
                why: "Gamma rays are the shortest wavelength and highest energy; radio waves are the longest.",
                hint: "The high-energy end of the spectrum has the shortest waves."
            )
        ]
    )
}
