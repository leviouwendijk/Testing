import Atomos
import Foundation
import Testing

private enum StreamingDemoFailure: Error {
    case failed
}

private let streamingClock = MonotonicClock()

private func pause() {
    streamingClock.sleep(
        for: .init(
            seconds: 1
        )
    )
}

let output = ClosureTestTextOutput { text in
    FileHandle.standardOutput.write(
        Data(
            text.utf8
        )
    )
}

let reporter = PlainTextTestReporter(
    output: output
)

let suite = TestSuite(
    "streaming-demo",
    title: "Testing streaming demo"
) {
    Test("first-chunk") {
        pause()
    }

    Test("second-chunk") {
        pause()
    }

    Test("third-chunk") {
        pause()
    }

    Test("fourth-chunk") {
        pause()
    }
}

let result = await TestRunner.run(
    suite,
    sink: reporter
)

if result.isFailure {
    throw StreamingDemoFailure.failed
}
