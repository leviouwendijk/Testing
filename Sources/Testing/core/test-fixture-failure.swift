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
    TestFlowDiagnosticProviding
{
    public let phase: TestFixturePhase
    public let primaryDiagnostics: [TestFlowDiagnostic]
    public let fixtureDiagnostics: [TestFlowDiagnostic]
    public let teardownDiagnostics: [TestFlowDiagnostic]

    public init(
        phase: TestFixturePhase,
        primaryDiagnostics: [TestFlowDiagnostic],
        fixtureDiagnostics: [TestFlowDiagnostic] = [],
        teardownDiagnostics: [TestFlowDiagnostic] = []
    ) {
        self.phase = phase
        self.primaryDiagnostics = primaryDiagnostics
        self.fixtureDiagnostics = fixtureDiagnostics
        self.teardownDiagnostics = teardownDiagnostics
    }

    public var testFlowDiagnostics: [TestFlowDiagnostic] {
        var diagnostics: [TestFlowDiagnostic] = [
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
        testFlowDiagnostics
            .map(\.description)
            .joined(
                separator: "\n"
            )
    }
}
