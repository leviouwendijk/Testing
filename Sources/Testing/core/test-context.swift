public struct TestContext: Sendable {
    private let recorder: TestRecorder

    public init() {
        self.recorder = .init()
    }

    init(
        recorder: TestRecorder
    ) {
        self.recorder = recorder
    }

    public func record(
        _ issue: TestIssue
    ) async {
        await recorder.record(issue)
    }

    public func record(
        _ diagnostic: TestFlowDiagnostic
    ) async {
        await recorder.record(diagnostic)
    }

    public func record(
        contentsOf diagnostics: [TestFlowDiagnostic]
    ) async {
        await recorder.record(
            contentsOf: diagnostics
        )
    }

    public func expect(
        _ condition: @autoclosure () -> Bool,
        _ message: String = "expected condition to be true",
        fileID: String = #fileID,
        filePath: String = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) async {
        guard !condition() else {
            return
        }

        await recorder.record(
            TestIssue(
                kind: .expectation,
                message: message,
                sourceLocation: .init(
                    fileID: fileID,
                    filePath: filePath,
                    line: line,
                    column: column
                ),
                actual: "false",
                expected: "true"
            )
        )
    }

    public func expectEqual<Value: Equatable>(
        _ actual: Value,
        _ expected: Value,
        _ message: String = "values were not equal",
        fileID: String = #fileID,
        filePath: String = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) async {
        guard actual != expected else {
            return
        }

        await recorder.record(
            TestIssue(
                kind: .expectation,
                message: message,
                sourceLocation: .init(
                    fileID: fileID,
                    filePath: filePath,
                    line: line,
                    column: column
                ),
                actual: String(
                    describing: actual
                ),
                expected: String(
                    describing: expected
                )
            )
        )
    }

    public func expect<Value: Equatable>(
        _ actual: Value,
        equals expected: Value,
        _ message: String = "values were not equal",
        fileID: String = #fileID,
        filePath: String = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) async {
        await expectEqual(
            actual,
            expected,
            message,
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
        )
    }

    public func require(
        _ condition: @autoclosure () -> Bool,
        _ message: String = "required condition was false",
        fileID: String = #fileID,
        filePath: String = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) throws {
        guard condition() else {
            throw TestRequirementFailure(
                issue: .init(
                    kind: .requirement,
                    message: message,
                    sourceLocation: .init(
                        fileID: fileID,
                        filePath: filePath,
                        line: line,
                        column: column
                    ),
                    actual: "false",
                    expected: "true"
                )
            )
        }
    }

    public func requireEqual<Value: Equatable>(
        _ actual: Value,
        _ expected: Value,
        _ message: String = "required values were not equal",
        fileID: String = #fileID,
        filePath: String = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) throws {
        guard actual == expected else {
            throw TestRequirementFailure(
                issue: .init(
                    kind: .requirement,
                    message: message,
                    sourceLocation: .init(
                        fileID: fileID,
                        filePath: filePath,
                        line: line,
                        column: column
                    ),
                    actual: String(
                        describing: actual
                    ),
                    expected: String(
                        describing: expected
                    )
                )
            )
        }
    }

    public func require<Value: Equatable>(
        _ actual: Value,
        equals expected: Value,
        _ message: String = "required values were not equal",
        fileID: String = #fileID,
        filePath: String = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) throws {
        try requireEqual(
            actual,
            expected,
            message,
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
        )
    }
}
