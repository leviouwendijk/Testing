public protocol TestTextOutput: Sendable {
    func write(
        _ text: String
    ) async
}

public struct ClosureTestTextOutput:
    TestTextOutput,
    Sendable
{
    private let operation:
        @Sendable (String) async -> Void

    public init(
        _ operation:
            @escaping @Sendable (String) async -> Void
    ) {
        self.operation = operation
    }

    public func write(
        _ text: String
    ) async {
        await operation(
            text
        )
    }
}

public actor BufferedTestTextOutput:
    TestTextOutput
{
    private var chunks: [String]

    public init() {
        self.chunks = []
    }

    public func write(
        _ text: String
    ) async {
        chunks.append(
            text
        )
    }

    public func snapshot() -> [String] {
        chunks
    }

    public func rendered() -> String {
        chunks.joined()
    }

    public func reset() {
        chunks.removeAll(
            keepingCapacity: true
        )
    }
}
