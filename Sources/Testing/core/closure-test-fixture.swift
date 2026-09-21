public struct ClosureTestFixture<Handle: TestFixtureHandle>:
    TestFixture,
    Sendable
{
    private let startOperation: @Sendable () async throws -> Handle

    public init(
        start: @escaping @Sendable () async throws -> Handle
    ) {
        self.startOperation = start
    }

    public func start() async throws -> Handle {
        try await startOperation()
    }
}

public actor ClosureTestFixtureHandle:
    TestFixtureHandle
{
    private let diagnosticsOperation: @Sendable () async -> [TestFlowDiagnostic]
    private let teardownOperation: @Sendable () async throws -> Void
    private var didTeardown: Bool

    public init(
        diagnostics: @escaping @Sendable () async -> [TestFlowDiagnostic] = { [] },
        teardown: @escaping @Sendable () async throws -> Void
    ) {
        self.diagnosticsOperation = diagnostics
        self.teardownOperation = teardown
        self.didTeardown = false
    }

    public func diagnostics() async -> [TestFlowDiagnostic] {
        await diagnosticsOperation()
    }

    public func teardown() async throws {
        guard !didTeardown else {
            return
        }

        didTeardown = true
        try await teardownOperation()
    }
}
