public struct TestRecording:
    Sendable,
    Hashable
{
    public let issues: [TestIssue]
    public let diagnostics: [TestFlowDiagnostic]

    public init(
        issues: [TestIssue] = [],
        diagnostics: [TestFlowDiagnostic] = []
    ) {
        self.issues = issues
        self.diagnostics = diagnostics
    }
}

public actor TestRecorder {
    private var issues: [TestIssue]
    private var diagnostics: [TestFlowDiagnostic]

    public init() {
        self.issues = []
        self.diagnostics = []
    }

    public func record(
        _ issue: TestIssue
    ) {
        issues.append(issue)
    }

    public func record(
        _ diagnostic: TestFlowDiagnostic
    ) {
        diagnostics.append(diagnostic)
    }

    public func record(
        contentsOf diagnostics: [TestFlowDiagnostic]
    ) {
        self.diagnostics.append(
            contentsOf: diagnostics
        )
    }

    public func snapshot() -> TestRecording {
        .init(
            issues: issues,
            diagnostics: diagnostics
        )
    }
}
