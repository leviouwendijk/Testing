import Foundation

public struct TestFlowAssertionFailure:
    Error,
    Sendable,
    LocalizedError,
    CustomStringConvertible,
    TestDiagnosticProviding
{
    public var label: String
    public var message: String
    public var actual: String?
    public var expected: String?
    public var diagnostics: [TestDiagnostic]
    public var sourceLocation: TestSourceLocation?

    public init(
        label: String,
        message: String,
        actual: String? = nil,
        expected: String? = nil,
        diagnostics: [TestDiagnostic] = [],
        sourceLocation: TestSourceLocation? = nil
    ) {
        self.label = label
        self.message = message
        self.actual = actual
        self.expected = expected
        self.diagnostics = diagnostics
        self.sourceLocation = sourceLocation
    }

    public var errorDescription: String? {
        description
    }

    public var testDiagnostics: [TestDiagnostic] {
        var out: [TestDiagnostic] = [
            .message(
                "\(label): \(message)"
            )
        ]

        if let sourceLocation {
            out.append(
                .field(
                    "source",
                    sourceLocation.description
                )
            )
        }

        if let expected {
            out.append(
                .field(
                    "expected",
                    expected
                )
            )
        }

        if let actual {
            out.append(
                .field(
                    "actual",
                    actual
                )
            )
        }

        out.append(
            contentsOf: diagnostics
        )

        return out
    }

    public var description: String {
        testDiagnostics
            .map(\.description)
            .joined(
                separator: "\n"
            )
    }
}
