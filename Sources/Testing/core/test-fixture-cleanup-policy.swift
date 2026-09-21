public enum TestFixtureFailureCleanupDisposition: Sendable {
    case report
    case propagatePrimaryError
}

public protocol TestFixtureCleanupPolicy: Sendable {
    func cleanup(
        _ operation: @escaping @Sendable () async throws -> Void
    ) async throws

    func cleanupAfterFailure(
        _ primaryError: any Error,
        operation: @escaping @Sendable () async throws -> Void
    ) async throws -> TestFixtureFailureCleanupDisposition
}

public extension TestFixtureCleanupPolicy {
    func cleanupAfterFailure(
        _ primaryError: any Error,
        operation: @escaping @Sendable () async throws -> Void
    ) async throws -> TestFixtureFailureCleanupDisposition {
        try await cleanup(
            operation
        )

        return .report
    }
}

public struct DirectTestFixtureCleanupPolicy:
    TestFixtureCleanupPolicy
{
    public init() {}

    public func cleanup(
        _ operation: @escaping @Sendable () async throws -> Void
    ) async throws {
        try await operation()
    }
}
