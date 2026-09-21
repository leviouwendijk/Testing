import Foundation

public extension Expect {
    static func greaterThan<T: Comparable>(
        _ actual: T,
        _ expected: T,
        _ label: String
    ) throws {
        guard actual > expected else {
            throw TestFlowAssertionFailure(
                label: label,
                message: "value was not greater than expected",
                actual: String(describing: actual),
                expected: "> \(String(describing: expected))"
            )
        }
    }

    static func lessThan<T: Comparable>(
        _ actual: T,
        _ expected: T,
        _ label: String
    ) throws {
        guard actual < expected else {
            throw TestFlowAssertionFailure(
                label: label,
                message: "value was not less than expected",
                actual: String(describing: actual),
                expected: "< \(String(describing: expected))"
            )
        }
    }

    static func isEmpty<C: Collection>(
        _ actual: C,
        _ label: String
    ) throws {
        guard actual.isEmpty else {
            throw TestFlowAssertionFailure(
                label: label,
                message: "collection was not empty",
                actual: String(describing: actual.count),
                expected: "0"
            )
        }
    }

    static func notEmpty<C: Collection>(
        _ actual: C,
        _ label: String
    ) throws {
        guard !actual.isEmpty else {
            throw TestFlowAssertionFailure(
                label: label,
                message: "collection was empty",
                actual: "0",
                expected: "non-empty"
            )
        }
    }

    static func contains(
        _ actual: String,
        _ expected: String,
        _ label: String
    ) throws {
        guard actual.contains(expected) else {
            throw TestFlowAssertionFailure(
                label: label,
                message: "string did not contain expected substring",
                actual: actual,
                expected: expected
            )
        }
    }

    static func doesNotContain(
        _ actual: String,
        _ expected: String,
        _ label: String
    ) throws {
        guard !actual.contains(expected) else {
            throw TestFlowAssertionFailure(
                label: label,
                message: "string contained forbidden substring",
                actual: actual,
                expected: "not containing \(expected)"
            )
        }
    }

    static func approximatelyEqual(
        _ actual: Double,
        _ expected: Double,
        tolerance: Double,
        _ label: String
    ) throws {
        let difference = abs(actual - expected)

        guard difference <= tolerance else {
            throw TestFlowAssertionFailure(
                label: label,
                message: "value was outside tolerance",
                actual: String(describing: actual),
                expected: "\(expected) ± \(tolerance)"
            )
        }
    }

    static func matches(
        _ actual: String,
        pattern: String,
        _ label: String
    ) throws {
        guard actual.range(
            of: pattern,
            options: .regularExpression
        ) != nil else {
            throw TestFlowAssertionFailure(
                label: label,
                message: "string did not match pattern",
                actual: actual,
                expected: pattern
            )
        }
    }
}
