//
//  MathEvaluator.swift
//  Quark
//
//  A small, total arithmetic evaluator. It exists so Quark never has to take
//  a number on faith: when the on-device model proposes a numeric exercise it
//  must also supply a `check` expression, and this evaluator re-derives the
//  answer before the item is allowed anywhere near a learner.
//
//  Recursive-descent over + - * / ^ with parentheses, unary sign, percent,
//  and a few named constants. Anything it cannot parse returns nil rather
//  than guessing.
//

import Foundation

enum MathEvaluator {
    static func evaluate(_ input: String) -> Double? {
        let tokens = tokenize(input)
        guard !tokens.isEmpty else { return nil }
        var parser = Parser(tokens: tokens)
        guard let value = parser.parseExpression(), parser.isAtEnd else { return nil }
        guard value.isFinite else { return nil }
        return value
    }

    /// Convenience for guardrails: does `expression` evaluate to `expected`?
    static func confirms(_ expression: String, equals expected: Double, tolerance: Double = 1e-6) -> Bool {
        guard let value = evaluate(expression) else { return false }
        return abs(value - expected) <= max(tolerance, 1e-9)
    }

    // MARK: - Tokens

    private enum Token: Equatable {
        case number(Double)
        case plus, minus, times, divide, power
        case percent
        case lparen, rparen
        case function(String)
    }

    private static let constants: [String: Double] = [
        "pi": Double.pi,
        "π": Double.pi,
        "e": M_E
    ]

    private static let functions: Set<String> = ["sqrt", "abs"]

    private static func tokenize(_ input: String) -> [Token] {
        var tokens: [Token] = []
        let characters = Array(input)
        var index = 0

        while index < characters.count {
            let character = characters[index]

            if character.isWhitespace || character == "," || character == "_" {
                index += 1
                continue
            }

            if character.isNumber || character == "." {
                var literal = ""
                while index < characters.count, characters[index].isNumber || characters[index] == "." {
                    literal.append(characters[index])
                    index += 1
                }
                guard let value = Double(literal) else { return [] }
                tokens.append(.number(value))
                continue
            }

            if character.isLetter || character == "π" {
                var word = ""
                while index < characters.count, characters[index].isLetter || characters[index] == "π" {
                    word.append(characters[index])
                    index += 1
                }
                let lowered = word.lowercased()
                if let constant = constants[lowered] {
                    tokens.append(.number(constant))
                } else if functions.contains(lowered) {
                    tokens.append(.function(lowered))
                } else {
                    return []
                }
                continue
            }

            switch character {
            case "+": tokens.append(.plus)
            case "-", "−", "–": tokens.append(.minus)
            case "*", "×", "·": tokens.append(.times)
            case "/", "÷": tokens.append(.divide)
            case "^": tokens.append(.power)
            case "%": tokens.append(.percent)
            case "(", "[": tokens.append(.lparen)
            case ")", "]": tokens.append(.rparen)
            default: return []
            }
            index += 1
        }

        return tokens
    }

    // MARK: - Parser

    private struct Parser {
        let tokens: [Token]
        var position = 0

        var isAtEnd: Bool { position >= tokens.count }

        private func peek() -> Token? { position < tokens.count ? tokens[position] : nil }

        mutating func parseExpression() -> Double? {
            guard var value = parseTerm() else { return nil }
            while let token = peek(), token == .plus || token == .minus {
                position += 1
                guard let rhs = parseTerm() else { return nil }
                value = (token == .plus) ? value + rhs : value - rhs
            }
            return value
        }

        private mutating func parseTerm() -> Double? {
            guard var value = parsePower() else { return nil }
            while let token = peek(), token == .times || token == .divide {
                position += 1
                guard let rhs = parsePower() else { return nil }
                if token == .divide {
                    guard rhs != 0 else { return nil }
                    value /= rhs
                } else {
                    value *= rhs
                }
            }
            return value
        }

        /// Right-associative, as in 2^3^2 = 512.
        private mutating func parsePower() -> Double? {
            guard let base = parseUnary() else { return nil }
            guard peek() == .power else { return base }
            position += 1
            guard let exponent = parsePower() else { return nil }
            let result = pow(base, exponent)
            return result.isFinite ? result : nil
        }

        private mutating func parseUnary() -> Double? {
            switch peek() {
            case .minus:
                position += 1
                guard let value = parseUnary() else { return nil }
                return -value
            case .plus:
                position += 1
                return parseUnary()
            default:
                return parsePostfix()
            }
        }

        private mutating func parsePostfix() -> Double? {
            guard var value = parsePrimary() else { return nil }
            while peek() == .percent {
                position += 1
                value /= 100
            }
            return value
        }

        private mutating func parsePrimary() -> Double? {
            guard let token = peek() else { return nil }
            switch token {
            case .number(let value):
                position += 1
                return value
            case .function(let name):
                position += 1
                guard peek() == .lparen else { return nil }
                position += 1
                guard let argument = parseExpression(), peek() == .rparen else { return nil }
                position += 1
                return apply(name, to: argument)
            case .lparen:
                position += 1
                guard let value = parseExpression(), peek() == .rparen else { return nil }
                position += 1
                return value
            default:
                return nil
            }
        }

        private func apply(_ name: String, to argument: Double) -> Double? {
            switch name {
            case "sqrt":
                guard argument >= 0 else { return nil }
                return argument.squareRoot()
            case "abs":
                return abs(argument)
            default:
                return nil
            }
        }
    }
}
