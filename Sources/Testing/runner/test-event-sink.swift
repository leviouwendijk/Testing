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

public struct TestClosureEventSink:
    TestEventSink,
    Sendable
{
    private let operation: @Sendable (TestExecutionEvent) async -> Void

    public init(
        _ operation: @escaping @Sendable (TestExecutionEvent) async -> Void
    ) {
        self.operation = operation
    }

    public func receive(
        _ event: TestExecutionEvent
    ) async {
        await operation(event)
    }
}

public struct TestCompositeEventSink:
    TestEventSink,
    Sendable
{
    public let sinks: [any TestEventSink]

    public init(
        _ sinks: [any TestEventSink]
    ) {
        self.sinks = sinks
    }

    public init(
        _ first: any TestEventSink,
        _ second: any TestEventSink
    ) {
        self.sinks = [
            first,
            second,
        ]
    }

    public func receive(
        _ event: TestExecutionEvent
    ) async {
        for sink in sinks {
            await sink.receive(event)
        }
    }
}
