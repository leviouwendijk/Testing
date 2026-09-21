public enum TestFixturePhase:
    String,
    Sendable,
    Hashable
{
    case start
    case operation
    case teardown
}

public struct TestFixtureFailure:
    Error,
    Sendable,
    CustomStringConvertible,
    TestDiagnosticProviding
{
    public let phase: TestFixturePhase
    public let primaryDiagnostics: [TestDiagnostic]
    public let fixtureDiagnostics: [TestDiagnostic]
    public let teardownDiagnostics: [TestDiagnostic]

    public init(
        phase: TestFixturePhase,
        primaryDiagnostics: [TestDiagnostic],
        fixtureDiagnostics: [TestDiagnostic] = [],
        teardownDiagnostics: [TestDiagnostic] = []
    ) {
        self.phase = phase
        self.primaryDiagnostics = primaryDiagnostics
        self.fixtureDiagnostics = fixtureDiagnostics
        self.teardownDiagnostics = teardownDiagnostics
    }

    public var testDiagnostics: [TestDiagnostic] {
        var diagnostics: [TestDiagnostic] = [
            .field(
                "fixture_phase",
                phase.rawValue
            )
        ]

        diagnostics.append(
            contentsOf: primaryDiagnostics
        )

        if !fixtureDiagnostics.isEmpty {
            diagnostics.append(
                .message("fixture diagnostics")
            )
            diagnostics.append(
                contentsOf: fixtureDiagnostics
            )
        }

        if !teardownDiagnostics.isEmpty {
            diagnostics.append(
                .message("fixture teardown diagnostics")
            )
            diagnostics.append(
                contentsOf: teardownDiagnostics
            )
        }

        return diagnostics
    }

    public var description: String {
        testDiagnostics
            .map(\.description)
            .joined(
                separator: "\n"
            )
    }
}
