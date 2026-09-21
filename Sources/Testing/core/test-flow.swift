import Foundation

public struct TestFlow: Sendable, Identifiable {
    public let id: String
    public let title: String?
    public let tags: Set<String>
    public let skipReason: String?
    public let expectedFailure: String?

    private let operation: @Sendable () async -> TestFlowResult

    public init(
        id: String,
        title: String? = nil,
        tags: Set<String> = [],
        skip: String? = nil,
        expectedFailure: String? = nil,
        operation: @escaping @Sendable () async throws -> TestFlowResult
    ) {
        self.id = id
        self.title = title
        self.tags = tags
        self.skipReason = skip
        self.expectedFailure = expectedFailure
        self.operation = {
            do {
                return try await operation()
            } catch let skip as TestFlowSkip {
                return .skipped(
                    name: id,
                    reason: skip.reason,
                    diagnostics: skip.diagnostics
                )
            } catch {
                return .failed(
                    name: id,
                    diagnostics: TestErrorDiagnostics.diagnostics(
                        for: error
                    )
                )
            }
        }
    }

    public init(
        _ id: String,
        title: String? = nil,
        tags: Set<String> = [],
        skip: String? = nil,
        expectedFailure: String? = nil,
        operation: @escaping @Sendable () async throws -> [TestDiagnostic]
    ) {
        self.init(
            id: id,
            title: title,
            tags: tags,
            skip: skip,
            expectedFailure: expectedFailure
        ) {
            .passed(
                name: id,
                diagnostics: try await operation()
            )
        }
    }

    public var displayName: String {
        title ?? id
    }

    public func run() async -> TestFlowResult {
        let startedAt = Date()

        if let skipReason {
            return .skipped(
                name: id,
                displayName: displayName,
                reason: skipReason,
                startedAt: startedAt,
                endedAt: Date(),
                tags: tags
            )
        }

        let result = await operation()
        let endedAt = Date()

        var final = result.withRun(
            name: id,
            displayName: displayName,
            tags: tags,
            startedAt: startedAt,
            endedAt: endedAt
        )

        if let expectedFailure {
            final = final.markExpectedFailure(
                reason: expectedFailure
            )
        }

        return final
    }
}
