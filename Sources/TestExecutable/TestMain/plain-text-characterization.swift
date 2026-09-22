import Testing

private struct PlainTextCharacterizationFailure:
    Error,
    CustomStringConvertible
{
    let message: String

    var description: String {
        message
    }
}

private actor StreamingTextCapture {
    private var chunks: [String] = []

    func append(
        _ text: String
    ) {
        chunks.append(
            text
        )
    }

    func snapshot() -> [String] {
        chunks
    }
}

func characterizePlainTextProjectionAndStreaming() async throws {
    var projector = PlainTextTestProjector()

    let header = projector.project(
        .run_started(
            title: "Projection",
            totalTests: 2
        )
    )

    try plainTextCheck(
        header == [
            "Projection · 2 tests",
            "",
        ],
        "plain-text projector header changed unexpectedly"
    )

    let capture = StreamingTextCapture()
    let output = ClosureTestTextOutput { text in
        await capture.append(
            text
        )
    }
    let reporter = PlainTextTestReporter(
        output: output
    )

    let suite = TestSuite(
        "projection-root",
        title: "Projection"
    ) {
        Test("fast") { test in
            await test.record(
                TestMetric(
                    "items",
                    value: 1,
                    unit: .count
                )
            )
        }

        Test("failure") { test in
            await test.record(
                .field(
                    "case",
                    "synthetic"
                )
            )
            await test.expect(
                false,
                "expected projector failure"
            )
        }
    }

    let result = await TestRunner.run(
        suite,
        sink: reporter
    )
    let rendered = await reporter.rendered()
    let chunks = await capture.snapshot()

    try plainTextCheck(
        result.results.count == 2,
        "plain-text characterization suite did not produce two results"
    )
    try plainTextCheck(
        chunks.count >= 4,
        "plain-text reporter did not stream multiple output chunks"
    )
    try plainTextCheck(
        chunks.first?.contains(
            "Projection · 2 tests"
        ) == true,
        "plain-text stream did not start with the run header"
    )
    try plainTextCheck(
        chunks.contains {
            $0.contains(
                "PASS  fast"
            )
        },
        "plain-text stream did not emit a passing result before run completion"
    )
    try plainTextCheck(
        chunks.contains {
            $0.contains(
                "FAIL  failure"
            )
        },
        "plain-text stream did not emit a failing result before run completion"
    )
    try plainTextCheck(
        rendered.contains(
            "projection-root/fast"
        ) == false,
        "plain-text reporter did not shorten the root suite path"
    )
    try plainTextCheck(
        rendered.contains(
            "expected projector failure"
        ),
        "plain-text reporter did not render the failure message"
    )
    try plainTextCheck(
        rendered.contains(
            "expected: true"
        ),
        "plain-text reporter did not render expected failure data"
    )
    try plainTextCheck(
        rendered.contains(
            "actual:   false"
        ),
        "plain-text reporter did not render actual failure data"
    )
    try plainTextCheck(
        rendered.contains(
            "case: synthetic"
        ),
        "plain-text reporter did not structurally render field diagnostics"
    )
    try plainTextCheck(
        rendered.contains(
            "items: 1 count"
        ),
        "plain-text reporter did not render typed metrics"
    )
    try plainTextCheck(
        rendered.contains(
            "1 passed · 1 failed · 0 skipped ·"
        ),
        "plain-text reporter did not render the dense summary"
    )

    let buffered = BufferedTestTextOutput()
    await buffered.write(
        "one\n"
    )
    await buffered.write(
        "two\n"
    )

    let bufferedRendered = await buffered.rendered()

    try plainTextCheck(
        bufferedRendered == "one\ntwo\n",
        "buffered text output did not preserve streamed chunks"
    )

    print(
        "ttest: plain-text projection and streaming passed"
    )
}

private func plainTextCheck(
    _ condition: @autoclosure () -> Bool,
    _ message: String
) throws {
    guard condition() else {
        throw PlainTextCharacterizationFailure(
            message: message
        )
    }
}
