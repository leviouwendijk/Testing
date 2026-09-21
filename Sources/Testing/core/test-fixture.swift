public protocol TestFixture: Sendable {
    associatedtype Handle: TestFixtureHandle

    /// Acquire the fixture and return only once it is ready for immediate use.
    ///
    /// If acquisition partially succeeds and then fails, this method owns cleanup
    /// of that partial state before throwing.
    func start() async throws -> Handle
}

public protocol TestFixtureHandle: Sendable {
    /// Return best-effort diagnostic evidence for the fixture.
    ///
    /// Diagnostics must remain available after teardown so callers can include
    /// terminal fixture state in a failed test result.
    func diagnostics() async -> [TestFlowDiagnostic]

    /// Release the fixture and all resources owned by it.
    ///
    /// Teardown must be idempotent so failure recovery can safely attempt it
    /// without requiring knowledge of the fixture's internal lifecycle state.
    func teardown() async throws
}
