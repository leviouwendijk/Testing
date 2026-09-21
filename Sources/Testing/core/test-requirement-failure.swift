public struct TestRequirementFailure:
    Error,
    Sendable,
    CustomStringConvertible,
    TestFlowDiagnosticProviding
{
    public let issue: TestIssue

    public init(
        issue: TestIssue
    ) {
        self.issue = issue
    }

    public var testFlowDiagnostics: [TestFlowDiagnostic] {
        var diagnostics: [TestFlowDiagnostic] = [
            .message(issue.message),
            .field(
                "source",
                issue.sourceLocation.description
            ),
        ]

        if let expected = issue.expected {
            diagnostics.append(
                .field(
                    "expected",
                    expected
                )
            )
        }

        if let actual = issue.actual {
            diagnostics.append(
                .field(
                    "actual",
                    actual
                )
            )
        }

        diagnostics.append(
            contentsOf: issue.diagnostics
        )

        return diagnostics
    }

    public var description: String {
        issue.description
    }
}
