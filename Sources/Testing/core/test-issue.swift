public enum TestIssueKind:
    String,
    Sendable,
    Hashable,
    CaseIterable
{
    case expectation
    case requirement
    case error
    case timeout
    case infrastructure
    case legacy
}

public struct TestIssue:
    Sendable,
    Hashable,
    CustomStringConvertible
{
    public let kind: TestIssueKind
    public let message: String
    public let sourceLocation: TestSourceLocation
    public let actual: String?
    public let expected: String?
    public let diagnostics: [TestFlowDiagnostic]

    public init(
        kind: TestIssueKind,
        message: String,
        sourceLocation: TestSourceLocation,
        actual: String? = nil,
        expected: String? = nil,
        diagnostics: [TestFlowDiagnostic] = []
    ) {
        self.kind = kind
        self.message = message
        self.sourceLocation = sourceLocation
        self.actual = actual
        self.expected = expected
        self.diagnostics = diagnostics
    }

    public var description: String {
        var lines = [
            "\(kind.rawValue): \(message)",
            "at \(sourceLocation.description)",
        ]

        if let expected {
            lines.append(
                "expected: \(expected)"
            )
        }

        if let actual {
            lines.append(
                "actual: \(actual)"
            )
        }

        lines.append(
            contentsOf: diagnostics.map(\.description)
        )

        return lines.joined(
            separator: "\n"
        )
    }
}
