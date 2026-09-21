import Atomos

public actor PlainTextTestReporter:
    TestEventSink
{
    private let verbose: Bool
    private var outputLines: [String]

    public init(
        verbose: Bool = false
    ) {
        self.verbose = verbose
        self.outputLines = []
    }

    public func receive(
        _ event: TestExecutionEvent
    ) async {
        switch event {
        case .run_started(let title, let totalTests):
            outputLines.append(title)
            outputLines.append(
                "tests: \(totalTests)"
            )

        case .suite_started(let suite):
            if verbose {
                outputLines.append(
                    "suite \(suite.path)"
                )
            }

        case .test_started(let test):
            if verbose {
                outputLines.append(
                    "[RUN ] \(test.path)"
                )
            }

        case .issue_recorded(let issue, let test):
            outputLines.append(
                "    issue \(test.path): \(issue.message)"
            )
            outputLines.append(
                "        at \(issue.sourceLocation.description)"
            )

            if let expected = issue.expected {
                outputLines.append(
                    "        expected: \(expected)"
                )
            }

            if let actual = issue.actual {
                outputLines.append(
                    "        actual: \(actual)"
                )
            }

        case .diagnostic_recorded(let diagnostic, let test):
            if verbose {
                outputLines.append(
                    "    diagnostic \(test.path): \(diagnostic.description)"
                )
            }

        case .test_finished(let result):
            outputLines.append(
                "[\(label(result.outcome))] \(result.test.path) \(formatDuration(result.duration))"
            )

        case .suite_finished(let suite, let resultCount):
            if verbose {
                outputLines.append(
                    "suite finished \(suite.path): \(resultCount)"
                )
            }

        case .run_finished(let result):
            outputLines.append("")
            outputLines.append(
                "passed: \(result.passedCount)"
            )
            outputLines.append(
                "failed: \(result.failureCount)"
            )
            outputLines.append(
                "skipped: \(result.skippedCount)"
            )
            outputLines.append(
                "duration: \(formatDuration(result.duration))"
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
    }
}

private extension PlainTextTestReporter {
    func label(
        _ outcome: TestOutcome
    ) -> String {
        switch outcome {
        case .passed:
            "PASS"
        case .failed:
            "FAIL"
        case .skipped:
            "SKIP"
        case .expected_failure:
            "XFAIL"
        case .unexpected_pass:
            "XPASS"
        case .interrupted:
            "INT "
        }
    }

    func formatDuration(
        _ duration: MonotonicClock.Duration
    ) -> String {
        let negative = duration.nanoseconds < 0
        let magnitude = duration.nanoseconds.magnitude
        let wholeMilliseconds = magnitude / 1_000_000
        let fractionalMicroseconds = (
            magnitude % 1_000_000
        ) / 1_000

        let fraction: String

        if fractionalMicroseconds < 10 {
            fraction = "00\(fractionalMicroseconds)"
        } else if fractionalMicroseconds < 100 {
            fraction = "0\(fractionalMicroseconds)"
        } else {
            fraction = String(fractionalMicroseconds)
        }

        return "\(negative ? "-" : "")\(wholeMilliseconds).\(fraction)ms"
    }
}
