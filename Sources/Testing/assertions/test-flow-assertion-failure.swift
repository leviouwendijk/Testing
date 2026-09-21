import Foundation

public struct TestFlowAssertionFailure: Error, Sendable, LocalizedError, CustomStringConvertible, TestFlowDiagnosticProviding {
    public var label: String
    public var message: String
    public var actual: String?
    public var expected: String?
    public var diagnostics: [TestFlowDiagnostic]

    public init(
        label: String,
        message: String,
        actual: String? = nil,
        expected: String? = nil,
        diagnostics: [TestFlowDiagnostic] = []
    ) {
        self.label = label
        self.message = message
        self.actual = actual
        self.expected = expected
        self.diagnostics = diagnostics
    }

    public var errorDescription: String? {
        description
    }

    public var testFlowDiagnostics: [TestFlowDiagnostic] {
        var out: [TestFlowDiagnostic] = [
            .message("\(label): \(message)")
        ]

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
        testFlowDiagnostics
            .map(\.description)
            .joined(
                separator: "\n"
            )
    }
}
