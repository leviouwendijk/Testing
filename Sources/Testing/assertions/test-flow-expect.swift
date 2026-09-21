public enum Expect {}

public extension Expect {
    static func equal<T: Equatable>(
        _ actual: T,
        _ expected: T,
        _ label: String
    ) throws {
        guard actual == expected else {
            throw TestFlowAssertionFailure(
                label: label,
                message: "values were not equal",
                actual: String(describing: actual),
                expected: String(describing: expected)
            )
        }
    }

    static func notEqual<T: Equatable>(
        _ actual: T,
        _ expected: T,
        _ label: String
    ) throws {
        guard actual != expected else {
            throw TestFlowAssertionFailure(
                label: label,
                message: "values were unexpectedly equal",
                actual: String(describing: actual),
                expected: "not \(String(describing: expected))"
            )
        }
    }

    static func `true`(
        _ actual: Bool,
        _ label: String
    ) throws {
        guard actual else {
            throw TestFlowAssertionFailure(
                label: label,
                message: "condition was false",
                actual: "false",
                expected: "true"
            )
        }
    }

    static func `false`(
        _ actual: Bool,
        _ label: String
    ) throws {
        guard !actual else {
            throw TestFlowAssertionFailure(
                label: label,
                message: "condition was true",
                actual: "true",
                expected: "false"
            )
        }
    }

    @discardableResult
    static func notNil<T>(
        _ actual: T?,
        _ label: String
    ) throws -> T {
        guard let actual else {
            throw TestFlowAssertionFailure(
                label: label,
                message: "value was nil",
                actual: "nil",
                expected: "non-nil"
            )
        }

        return actual
    }

    static func isNil<T>(
        _ actual: T?,
        _ label: String
    ) throws {
        guard actual == nil else {
            throw TestFlowAssertionFailure(
                label: label,
                message: "value was not nil",
                actual: String(describing: actual),
                expected: "nil"
            )
        }
    }

    static func contains<Element: Equatable>(
        _ actual: [Element],
        _ expected: Element,
        _ label: String
    ) throws {
        guard actual.contains(expected) else {
            throw TestFlowAssertionFailure(
                label: label,
                message: "collection did not contain expected element",
                actual: actual.map { String(describing: $0) }.joined(separator: ","),
                expected: String(describing: expected)
            )
        }
    }

    static func containsOrdered<Element: Equatable>(
        _ actual: [Element],
        _ expected: [Element],
        _ label: String
    ) throws {
        var searchStart = actual.startIndex

        for expectedElement in expected {
            guard let index = actual[searchStart...].firstIndex(of: expectedElement) else {
                throw TestFlowAssertionFailure(
                    label: label,
                    message: "collection did not contain expected ordered element",
                    actual: actual.map { String(describing: $0) }.joined(separator: ","),
                    expected: expected.map { String(describing: $0) }.joined(separator: ",")
                )
            }

            searchStart = actual.index(
                after: index
            )
        }
    }

    static func throwsError(
        _ label: String,
        _ operation: () throws -> Void
    ) throws {
        do {
            try operation()
        } catch {
            return
        }

        throw TestFlowAssertionFailure(
            label: label,
            message: "operation did not throw",
            actual: "completed",
            expected: "throw"
        )
    }

    static func throwsError(
        _ label: String,
        _ operation: () async throws -> Void
    ) async throws {
        do {
            try await operation()
        } catch {
            return
        }

        throw TestFlowAssertionFailure(
            label: label,
            message: "operation did not throw",
            actual: "completed",
            expected: "throw"
        )
    }

    static func doesNotThrow(
        _ label: String,
        _ operation: () throws -> Void
    ) throws {
        do {
            try operation()
        } catch {
            throw TestFlowAssertionFailure(
                label: label,
                message: "operation threw unexpectedly",
                actual: String(describing: error),
                expected: "no throw"
            )
        }
    }

    static func doesNotThrow(
        _ label: String,
        _ operation: () async throws -> Void
    ) async throws {
        do {
            try await operation()
        } catch {
            throw TestFlowAssertionFailure(
                label: label,
                message: "operation threw unexpectedly",
                actual: String(describing: error),
                expected: "no throw"
            )
        }
    }
}
