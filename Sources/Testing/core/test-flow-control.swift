import Foundation

public struct TestFlowSkip: Error, Sendable, LocalizedError, CustomStringConvertible, TestDiagnosticProviding {
    public var reason: String
    public var diagnostics: [TestDiagnostic]

    public init(
        _ reason: String,
        diagnostics: [TestDiagnostic] = []
    ) {
        self.reason = reason
        self.diagnostics = diagnostics
    }

    public var errorDescription: String? {
        description
    }

    public var testDiagnostics: [TestDiagnostic] {
        [
            .field(
                "reason",
                reason
            )
        ] + diagnostics
    }

    public var description: String {
        "skipped: \(reason)"
    }
}

public extension TestFlowSkip {
    static func when(
        _ condition: Bool,
        _ reason: String,
        diagnostics: [TestDiagnostic] = []
    ) throws {
        if condition {
            throw Self(
                reason,
                diagnostics: diagnostics
            )
        }
    }

    static func unless(
        _ condition: Bool,
        _ reason: String,
        diagnostics: [TestDiagnostic] = []
    ) throws {
        if !condition {
            throw Self(
                reason,
                diagnostics: diagnostics
            )
        }
    }
}

public extension TestFlowResult {
    func markSkipped(
        reason: String,
        diagnostics: [TestDiagnostic] = []
    ) -> Self {
        var copy = self
        copy.status = .skipped
        copy.diagnostics.append(
            .field(
                "reason",
                reason
            )
        )
        copy.diagnostics.append(
            contentsOf: diagnostics
        )

        return copy
    }

    func markExpectedFailure(
        reason: String,
        diagnostics: [TestDiagnostic] = []
    ) -> Self {
        guard status != .skipped else {
            return self
        }

        var copy = self
        copy.status = isFailure ? .expected_failure : .unexpected_pass
        copy.diagnostics.append(
            .field(
                "expected_failure",
                reason
            )
        )
        copy.diagnostics.append(
            contentsOf: diagnostics
        )

        return copy
    }
}
