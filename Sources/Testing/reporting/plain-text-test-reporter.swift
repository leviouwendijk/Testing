public actor PlainTextTestReporter:
    TestEventSink
{
    private var projector: PlainTextTestProjector
    private let output: (any TestTextOutput)?
    private var outputLines: [String]

    public init(
        mode: PlainTextTestProjectionMode = .standard,
        output: (any TestTextOutput)? = nil
    ) {
        self.projector = PlainTextTestProjector(
            mode: mode
        )
        self.output = output
        self.outputLines = []
    }

    public init(
        verbose: Bool,
        output: (any TestTextOutput)? = nil
    ) {
        self.projector = PlainTextTestProjector(
            mode: verbose
                ? .verbose
                : .standard
        )
        self.output = output
        self.outputLines = []
    }

    public func receive(
        _ event: TestExecutionEvent
    ) async {
        let lines = projector.project(
            event
        )

        guard !lines.isEmpty else {
            return
        }

        outputLines.append(
            contentsOf: lines
        )

        if let output {
            await output.write(
                lines.joined(
                    separator: "\n"
                ) + "\n"
            )
        }
    }

    public func lines() -> [String] {
        outputLines
    }

    public func rendered() -> String {
        outputLines.joined(
            separator: "\n"
        )
    }

    public func reset() {
        outputLines.removeAll(
            keepingCapacity: true
        )
        projector = PlainTextTestProjector(
            mode: projector.mode,
            nameWidth: projector.nameWidth
        )
    }
}
