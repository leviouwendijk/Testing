import Foundation

public struct TestFlowResult: Sendable, Hashable {
    public var name: String
    public var displayName: String
    public var status: TestFlowStatus
    public var startedAt: Date
    public var endedAt: Date
    public var tags: Set<String>
    public var diagnostics: [TestFlowDiagnostic]
    public var steps: [TestFlowActionResult]

    public init(
        name: String,
        displayName: String? = nil,
        status: TestFlowStatus,
        startedAt: Date = Date(),
        endedAt: Date = Date(),
        tags: Set<String> = [],
        diagnostics: [TestFlowDiagnostic] = [],
        steps: [TestFlowActionResult] = []
    ) {
        self.name = name
        self.displayName = displayName ?? name
        self.status = status
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.tags = tags
        self.diagnostics = diagnostics
        self.steps = steps
    }

    public var duration: TimeInterval {
        endedAt.timeIntervalSince(startedAt)
    }

    public var isFailure: Bool {
        status.isFailure
    }
}

public extension TestFlowResult {
    static func passed(
        name: String,
        displayName: String? = nil,
        startedAt: Date = Date(),
        endedAt: Date = Date(),
        tags: Set<String> = [],
        diagnostics: [TestFlowDiagnostic] = [],
        steps: [TestFlowActionResult] = []
    ) -> Self {
        .init(
            name: name,
            displayName: displayName,
            status: .passed,
            startedAt: startedAt,
            endedAt: endedAt,
            tags: tags,
            diagnostics: diagnostics,
            steps: steps
        )
    }

    static func failed(
        name: String,
        displayName: String? = nil,
        startedAt: Date = Date(),
        endedAt: Date = Date(),
        tags: Set<String> = [],
        diagnostics: [TestFlowDiagnostic] = [],
        steps: [TestFlowActionResult] = []
    ) -> Self {
        .init(
            name: name,
            displayName: displayName,
            status: .failed,
            startedAt: startedAt,
            endedAt: endedAt,
            tags: tags,
            diagnostics: diagnostics,
            steps: steps
        )
    }

    static func skipped(
        name: String,
        displayName: String? = nil,
        reason: String,
        startedAt: Date = Date(),
        endedAt: Date = Date(),
        tags: Set<String> = [],
        diagnostics: [TestFlowDiagnostic] = [],
        steps: [TestFlowActionResult] = []
    ) -> Self {
        .init(
            name: name,
            displayName: displayName,
            status: .skipped,
            startedAt: startedAt,
            endedAt: endedAt,
            tags: tags,
            diagnostics: [
                .field(
                    "reason",
                    reason
                )
            ] + diagnostics,
            steps: steps
        )
    }

    static func pass(
        _ name: String,
        diagnostics: [TestFlowDiagnostic] = []
    ) -> Self {
        .passed(
            name: name,
            diagnostics: diagnostics
        )
    }

    static func fail(
        _ name: String,
        diagnostics: [TestFlowDiagnostic] = []
    ) -> Self {
        .failed(
            name: name,
            diagnostics: diagnostics
        )
    }

    func withRun(
        name: String,
        displayName: String,
        tags: Set<String>,
        startedAt: Date,
        endedAt: Date
    ) -> Self {
        var copy = self
        copy.name = name
        copy.displayName = displayName
        copy.tags = tags
        copy.startedAt = startedAt
        copy.endedAt = endedAt

        return copy
    }
}
