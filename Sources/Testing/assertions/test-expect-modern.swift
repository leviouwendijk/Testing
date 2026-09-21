public extension Expect {
    static func equal<Value: Equatable>(
        _ actual: Value,
        _ expected: Value,
        fileID: String = #fileID,
        filePath: String = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) throws {
        guard actual == expected else {
            throw TestFlowAssertionFailure(
                label: "equality",
                message: "values were not equal",
                actual: String(describing: actual),
                expected: String(describing: expected),
                sourceLocation: .init(
                    fileID: fileID,
                    filePath: filePath,
                    line: line,
                    column: column
                )
            )
        }
    }

    static func notEqual<Value: Equatable>(
        _ actual: Value,
        _ expected: Value,
        fileID: String = #fileID,
        filePath: String = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) throws {
        guard actual != expected else {
            throw TestFlowAssertionFailure(
                label: "inequality",
                message: "values were unexpectedly equal",
                actual: String(describing: actual),
                expected: "not \(String(describing: expected))",
                sourceLocation: .init(
                    fileID: fileID,
                    filePath: filePath,
                    line: line,
                    column: column
                )
            )
        }
    }

    static func greaterThanOrEqual<Value: Comparable>(
        _ actual: Value,
        _ expected: Value,
        fileID: String = #fileID,
        filePath: String = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) throws {
        guard actual >= expected else {
            throw TestFlowAssertionFailure(
                label: "ordering",
                message: "value was less than required lower bound",
                actual: String(describing: actual),
                expected: ">= \(String(describing: expected))",
                sourceLocation: .init(
                    fileID: fileID,
                    filePath: filePath,
                    line: line,
                    column: column
                )
            )
        }
    }

    static func lessThanOrEqual<Value: Comparable>(
        _ actual: Value,
        _ expected: Value,
        fileID: String = #fileID,
        filePath: String = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) throws {
        guard actual <= expected else {
            throw TestFlowAssertionFailure(
                label: "ordering",
                message: "value exceeded required upper bound",
                actual: String(describing: actual),
                expected: "<= \(String(describing: expected))",
                sourceLocation: .init(
                    fileID: fileID,
                    filePath: filePath,
                    line: line,
                    column: column
                )
            )
        }
    }

    static func inRange<Value: Comparable>(
        _ actual: Value,
        _ expected: ClosedRange<Value>,
        fileID: String = #fileID,
        filePath: String = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) throws {
        guard expected.contains(actual) else {
            throw TestFlowAssertionFailure(
                label: "range",
                message: "value was outside expected range",
                actual: String(describing: actual),
                expected: "\(expected.lowerBound)...\(expected.upperBound)",
                sourceLocation: .init(
                    fileID: fileID,
                    filePath: filePath,
                    line: line,
                    column: column
                )
            )
        }
    }

    static func count<CollectionType: Collection>(
        _ actual: CollectionType,
        _ expected: Int,
        fileID: String = #fileID,
        filePath: String = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) throws {
        guard actual.count == expected else {
            throw TestFlowAssertionFailure(
                label: "count",
                message: "collection count differed",
                actual: String(actual.count),
                expected: String(expected),
                sourceLocation: .init(
                    fileID: fileID,
                    filePath: filePath,
                    line: line,
                    column: column
                )
            )
        }
    }

    static func identical(
        _ actual: AnyObject,
        _ expected: AnyObject,
        fileID: String = #fileID,
        filePath: String = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) throws {
        guard actual === expected else {
            throw TestFlowAssertionFailure(
                label: "identity",
                message: "references were not identical",
                sourceLocation: .init(
                    fileID: fileID,
                    filePath: filePath,
                    line: line,
                    column: column
                )
            )
        }
    }

    @discardableResult
    static func throwsError<Failure: Error>(
        _ type: Failure.Type,
        operation: () throws -> Void,
        fileID: String = #fileID,
        filePath: String = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) throws -> Failure {
        do {
            try operation()
        } catch let error as Failure {
            return error
        } catch {
            throw TestFlowAssertionFailure(
                label: "throws",
                message: "operation threw an unexpected error type",
                actual: String(describing: error),
                expected: String(describing: type),
                sourceLocation: .init(
                    fileID: fileID,
                    filePath: filePath,
                    line: line,
                    column: column
                )
            )
        }

        throw TestFlowAssertionFailure(
            label: "throws",
            message: "operation did not throw",
            actual: "completed",
            expected: String(describing: type),
            sourceLocation: .init(
                fileID: fileID,
                filePath: filePath,
                line: line,
                column: column
            )
        )
    }

    @discardableResult
    static func throwsError<Failure: Error>(
        _ type: Failure.Type,
        operation: () async throws -> Void,
        fileID: String = #fileID,
        filePath: String = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) async throws -> Failure {
        do {
            try await operation()
        } catch let error as Failure {
            return error
        } catch {
            throw TestFlowAssertionFailure(
                label: "throws",
                message: "operation threw an unexpected error type",
                actual: String(describing: error),
                expected: String(describing: type),
                sourceLocation: .init(
                    fileID: fileID,
                    filePath: filePath,
                    line: line,
                    column: column
                )
            )
        }

        throw TestFlowAssertionFailure(
            label: "throws",
            message: "operation did not throw",
            actual: "completed",
            expected: String(describing: type),
            sourceLocation: .init(
                fileID: fileID,
                filePath: filePath,
                line: line,
                column: column
            )
        )
    }
}
