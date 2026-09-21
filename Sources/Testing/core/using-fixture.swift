public func usingFixture<Fixture, Result>(
    _ fixture: Fixture,
    cleanupPolicy: any TestFixtureCleanupPolicy = DirectTestFixtureCleanupPolicy(),
    operation: @escaping @Sendable (Fixture.Handle) async throws -> Result
) async throws -> Result
where
    Fixture: TestFixture,
    Result: Sendable
{
    let handle = try await fixture.start()

    let result: Result

    do {
        result = try await operation(
            handle
        )
    } catch {
        let operationError = error

        var teardownDiagnostics: [TestFlowDiagnostic] = []

        let cleanupDisposition: TestFixtureFailureCleanupDisposition

        do {
            cleanupDisposition = try await cleanupPolicy.cleanupAfterFailure(
                operationError
            ) {
                try await handle.teardown()
            }
        } catch {
            cleanupDisposition = .report
            teardownDiagnostics = TestFlowErrorDiagnostics.diagnostics(
                for: error
            )
        }

        switch cleanupDisposition {
        case .report:
            break

        case .propagatePrimaryError:
            throw operationError
        }

        let fixtureDiagnostics = await handle.diagnostics()

        throw TestFixtureFailure(
            phase: .operation,
            primaryDiagnostics: TestFlowErrorDiagnostics.diagnostics(
                for: operationError
            ),
            fixtureDiagnostics: fixtureDiagnostics,
            teardownDiagnostics: teardownDiagnostics
        )
    }

    do {
        try await cleanupPolicy.cleanup {
            try await handle.teardown()
        }
    } catch {
        let fixtureDiagnostics = await handle.diagnostics()

        throw TestFixtureFailure(
            phase: .teardown,
            primaryDiagnostics: TestFlowErrorDiagnostics.diagnostics(
                for: error
            ),
            fixtureDiagnostics: fixtureDiagnostics
        )
    }

    return result
}
