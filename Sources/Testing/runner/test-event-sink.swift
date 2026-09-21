public protocol TestEventSink: Sendable {
    func receive(
        _ event: TestExecutionEvent
    ) async
}

public struct NullTestEventSink:
    TestEventSink,
    Sendable
{
    public init() {}

    public func receive(
        _ event: TestExecutionEvent
    ) async {
        _ = event
    }
}
