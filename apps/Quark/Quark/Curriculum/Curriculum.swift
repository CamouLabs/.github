//
//  Curriculum.swift
//  Quark
//
//  The whole syllabus, assembled in code. Content ships with the binary: no
//  download, no CDN, no request that could tell anyone what a learner is
//  studying.
//

import Foundation

enum Curriculum {
    static let courses: [Course] = [
        MathCourse.course,
        PhysicsCourse.course,
        ChemistryCourse.course,
        BiologyCourse.course,
        ComputingCourse.course,
        DataCourse.course
    ]

    static func course(for track: TrackID) -> Course {
        courses.first { $0.track == track } ?? MathCourse.course
    }

    static var allLessons: [Lesson] { courses.flatMap(\.lessons) }

    static var allExercises: [Exercise] { allLessons.flatMap(\.exercises) }

    static func lessons(in tracks: [TrackID]) -> [Lesson] {
        tracks.flatMap { course(for: $0).lessons }
    }

    static func lesson(id: String) -> Lesson? {
        lessonIndex[id]
    }

    static func unit(containing lessonID: String) -> Unit? {
        for course in courses {
            for unit in course.units where unit.lessons.contains(where: { $0.id == lessonID }) {
                return unit
            }
        }
        return nil
    }

    static func track(containing lessonID: String) -> TrackID? {
        courses.first { $0.lessons.contains { $0.id == lessonID } }?.track
    }

    private static let lessonIndex: [String: Lesson] = Dictionary(
        allLessons.map { ($0.id, $0) },
        uniquingKeysWith: { first, _ in first }
    )

    /// Every word the curriculum itself uses. The topical guardrail requires
    /// generated material to overlap this vocabulary, which is a blunt but
    /// effective way to keep the coach inside the syllabus.
    static let vocabulary: Set<String> = {
        var words: Set<String> = []
        for lesson in allLessons {
            words.formUnion(tokens(lesson.title))
            words.formUnion(tokens(lesson.goal))
            for fact in lesson.facts { words.formUnion(tokens(fact)) }
            for exercise in lesson.exercises {
                words.formUnion(tokens(exercise.prompt))
                words.formUnion(tokens(exercise.explanation))
            }
        }
        for track in TrackID.allCases {
            words.formUnion(tokens(track.title))
            words.formUnion(tokens(track.blurb))
        }
        return words
    }()

    /// Stemmed form of the whole vocabulary, which is what the topical
    /// guardrail actually compares against.
    static let vocabularyStems: Set<String> = Set(vocabulary.map(stem))

    static func tokens(_ text: String) -> [String] {
        AnswerChecker.normalize(text)
            .split(separator: " ")
            .map(String.init)
            .filter { $0.count > 2 }
    }

    /// Tokens minus the words every sentence contains. Used by the topical and
    /// grounding guardrails, which care about subject matter rather than grammar.
    static func contentTokens(_ text: String) -> [String] {
        tokens(text).filter { !stopwords.contains($0) }
    }

    /// Content tokens with plural endings folded away, so "fraction" and
    /// "fractions" count as the same subject. Crude on purpose: full stemming
    /// would mostly add ways to be wrong.
    static func stems(_ text: String) -> Set<String> {
        Set(contentTokens(text).map(stem))
    }

    static func stem(_ word: String) -> String {
        guard word.count > 4 else { return word }
        if word.hasSuffix("ies") { return String(word.dropLast(3)) + "y" }
        if word.hasSuffix("es"), !word.hasSuffix("ses") { return String(word.dropLast(2)) }
        if word.hasSuffix("s"), !word.hasSuffix("ss"), !word.hasSuffix("us") {
            return String(word.dropLast())
        }
        return word
    }

    static let stopwords: Set<String> = [
        "the", "and", "for", "are", "but", "not", "you", "your", "with", "that",
        "this", "from", "they", "them", "then", "than", "have", "has", "had",
        "was", "were", "will", "would", "can", "could", "should", "what", "which",
        "when", "where", "who", "how", "why", "does", "did", "done", "into",
        "onto", "over", "under", "about", "after", "before", "between", "each",
        "much", "many", "more", "most", "some", "such", "only", "very", "just",
        "also", "any", "all", "one", "two", "its", "his", "her", "their", "our",
        "there", "here", "these", "those", "because", "while", "both", "same",
        "other", "another", "still", "even", "make", "makes", "made", "get",
        "gets", "give", "gives", "take", "takes", "say", "says", "know", "knows",
        "answer", "question", "options", "option", "correct", "learner", "lesson"
    ]
}
