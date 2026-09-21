public struct TestRecording:
    Sendable,
    Hashable
{
    public let issues: [TestIssue]
    public let diagnostics: [TestDiagnostic]
    public let metrics: [TestMetric]

    public init(
        issues: [TestIssue] = [],
        diagnostics: [TestDiagnostic] = [],
        metrics: [TestMetric] = []
    ) {
        self.issues = issues
        self.diagnostics = diagnostics
        self.metrics = metrics
    }
}

public actor TestRecorder {
    private var issues: [TestIssue]
    private var diagnostics: [TestDiagnostic]
    private var metrics: [TestMetric]

    public init() {
        self.issues = []
        self.diagnostics = []
        self.metrics = []
    }

    public func record(
        _ issue: TestIssue
    ) {
        issues.append(issue)
    }

    public func record(
        _ diagnostic: TestDiagnostic
    ) {
        diagnostics.append(diagnostic)
    }

    public func record(
        _ metric: TestMetric
    ) {
        metrics.append(metric)
    }

    public func record(
        contentsOf diagnostics: [TestDiagnostic]
    ) {
        self.diagnostics.append(
            contentsOf: diagnostics
        )
    }

    public func snapshot() -> TestRecording {
        .init(
            issues: issues,
            diagnostics: diagnostics,
            metrics: metrics
        )
    }
}
