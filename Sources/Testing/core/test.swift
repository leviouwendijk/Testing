public struct Test:
    Sendable,
    Identifiable
{
    public let id: String
    public let title: String?
    public let tags: Set<String>
    public let skipReason: String?
    public let expectedFailure: String?
    public let sourceLocation: TestSourceLocation

    let operation: @Sendable (TestContext) async throws -> Void

    public init(
        _ id: String,
        title: String? = nil,
        tags: Set<String> = [],
        skip: String? = nil,
        expectedFailure: String? = nil,
        sourceLocation: TestSourceLocation? = nil,
        fileID: String = #fileID,
        filePath: String = #filePath,
        line: UInt = #line,
        column: UInt = #column,
        operation: @escaping @Sendable (TestContext) async throws -> Void
    ) {
        self.id = id
        self.title = title
        self.tags = tags
        self.skipReason = skip
        self.expectedFailure = expectedFailure
        self.sourceLocation = sourceLocation ?? TestSourceLocation(
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
        )
        self.operation = operation
    }

    public init(
        _ id: String,
        title: String? = nil,
        tags: Set<String> = [],
        skip: String? = nil,
        expectedFailure: String? = nil,
        sourceLocation: TestSourceLocation? = nil,
        fileID: String = #fileID,
        filePath: String = #filePath,
        line: UInt = #line,
        column: UInt = #column,
        operation: @escaping @Sendable () async throws -> Void
    ) {
        self.init(
            id,
            title: title,
            tags: tags,
            skip: skip,
            expectedFailure: expectedFailure,
            sourceLocation: sourceLocation,
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
        ) { _ in
            try await operation()
        }
    }

    public var displayName: String {
        title ?? id
    }
}

public extension Test {
    init(
        _ flow: TestFlow,
        sourceLocation: TestSourceLocation? = nil,
        fileID: String = #fileID,
        filePath: String = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) {
        let sourceLocation = sourceLocation ?? TestSourceLocation(
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
        )

        self.init(
            flow.id,
            title: flow.title,
            tags: flow.tags,
            sourceLocation: sourceLocation
        ) { context in
            let result = await flow.run()

            if result.status == .skipped {
                throw TestFlowSkip(
                    "legacy flow skipped",
                    diagnostics: result.diagnostics
                )
            }

            await context.record(
                contentsOf: result.diagnostics
            )

            switch result.status {
            case .passed,
                 .expected_failure,
                 .secured:
                break

            case .failed,
                 .unexpected_pass,
                 .interrupted,
                 .vulnerable,
                 .exploited:
                await context.record(
                    TestIssue(
                        kind: .legacy,
                        message: "legacy TestFlow completed with status \(result.status.rawValue)",
                        sourceLocation: sourceLocation,
                        diagnostics: result.diagnostics
                    )
                )

            case .skipped:
                break
            }
        }
    }
}
