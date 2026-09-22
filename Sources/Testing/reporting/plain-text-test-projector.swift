import Atomos

public enum PlainTextTestProjectionMode:
    Sendable,
    Hashable
{
    case compact
    case standard
    case verbose
}

public struct PlainTextTestProjector: Sendable {
    public var mode: PlainTextTestProjectionMode
    public var nameWidth: Int

    private var rootSuitePath: String?

    public init(
        mode: PlainTextTestProjectionMode = .standard,
        nameWidth: Int = 32
    ) {
        self.mode = mode
        self.nameWidth = max(
            1,
            nameWidth
        )
        self.rootSuitePath = nil
    }

    public mutating func project(
        _ event: TestExecutionEvent
    ) -> [String] {
        switch event {
        case .run_started(
            let title,
            let totalTests
        ):
            rootSuitePath = nil

            if mode == .compact {
                return [
                    title,
                ]
            }

            return [
                "\(title) · \(totalTests) \(totalTests == 1 ? "test" : "tests")",
                "",
            ]

        case .suite_started(let suite):
            if rootSuitePath == nil {
                rootSuitePath = suite.path
                return []
            }

            guard mode == .verbose else {
                return []
            }

            return [
                "SUITE \(shortPath(suite.path))",
            ]

        case .test_started(let test):
            guard mode == .verbose else {
                return []
            }

            return [
                "RUN   \(shortPath(test.path))",
            ]

        case .issue_recorded,
             .diagnostic_recorded,
             .metric_recorded:
            return []

        case .test_finished(let result):
            return renderResult(
                result
            )

        case .suite_finished:
            return []

        case .run_finished(let result):
            return renderSummary(
                result
            )
        }
    }
}

private extension PlainTextTestProjector {
    func renderResult(
        _ result: TestResult
    ) -> [String] {
        let name = shortPath(
            result.test.path
        )
        let status = padded(
            label(result.outcome),
            to: 5
        )
        let displayName = padded(
            name,
            to: nameWidth
        )

        var lines: [String] = [
            "\(status) \(displayName) \(formatDuration(result.duration))",
        ]

        let showDetails = result.isFailure
            || result.outcome == .skipped
            || mode == .verbose

        if showDetails {
            appendIssues(
                result.issues,
                to: &lines
            )

            appendDiagnostics(
                result.diagnostics,
                to: &lines
            )
        }

        if mode != .compact {
            appendMetrics(
                result.metrics,
                to: &lines
            )
        }

        return lines
    }

    func renderSummary(
        _ result: TestRunResult
    ) -> [String] {
        let passed = count(
            .passed,
            in: result
        )
        let failed = count(
            .failed,
            in: result
        )
        let skipped = count(
            .skipped,
            in: result
        )
        let expectedFailures = count(
            .expected_failure,
            in: result
        )
        let unexpectedPasses = count(
            .unexpected_pass,
            in: result
        )
        let interrupted = count(
            .interrupted,
            in: result
        )

        var parts = [
            "\(passed) passed",
            "\(failed) failed",
            "\(skipped) skipped",
        ]

        if expectedFailures > 0 {
            parts.append(
                "\(expectedFailures) xfail"
            )
        }

        if unexpectedPasses > 0 {
            parts.append(
                "\(unexpectedPasses) xpass"
            )
        }

        if interrupted > 0 {
            parts.append(
                "\(interrupted) interrupted"
            )
        }

        parts.append(
            formatDuration(
                result.duration
            )
        )

        if mode == .compact {
            return [
                parts.joined(
                    separator: " · "
                ),
            ]
        }

        return [
            "",
            parts.joined(
                separator: " · "
            ),
        ]
    }

    func appendIssues(
        _ issues: [TestIssue],
        to lines: inout [String]
    ) {
        guard !issues.isEmpty else {
            return
        }

        lines.append("")

        if issues.count > 1 {
            lines.append(
                "    \(issues.count) issues"
            )
        }

        for (
            index,
            issue
        ) in issues.enumerated() {
            let prefix = issues.count > 1
                ? "\(index + 1)."
                : "issue"

            lines.append(
                "    \(prefix) \(issue.message)"
            )
            lines.append(
                "        at \(source(issue.sourceLocation))"
            )

            if let expected = issue.expected {
                lines.append(
                    "        expected: \(expected)"
                )
            }

            if let actual = issue.actual {
                lines.append(
                    "        actual:   \(actual)"
                )
            }

            for diagnostic in issue.diagnostics {
                lines.append(
                    contentsOf: renderDiagnostic(
                        diagnostic,
                        indent: "        "
                    )
                )
            }
        }
    }

    func appendDiagnostics(
        _ diagnostics: [TestDiagnostic],
        to lines: inout [String]
    ) {
        guard !diagnostics.isEmpty else {
            return
        }

        if lines.last != "" {
            lines.append("")
        }

        for diagnostic in diagnostics {
            lines.append(
                contentsOf: renderDiagnostic(
                    diagnostic,
                    indent: "    "
                )
            )
        }
    }

    func appendMetrics(
        _ metrics: [TestMetric],
        to lines: inout [String]
    ) {
        guard !metrics.isEmpty else {
            return
        }

        for metric in metrics {
            lines.append(
                "    \(renderMetric(metric))"
            )
        }
    }

    func renderDiagnostic(
        _ diagnostic: TestDiagnostic,
        indent: String
    ) -> [String] {
        switch diagnostic {
        case .message(let value):
            return indentedLines(
                value,
                indent: indent
            )

        case .field(
            let name,
            let value
        ):
            return [
                "\(indent)\(name): \(value)",
            ]

        case .section(
            let title,
            let values
        ):
            return [
                "\(indent)\(title)",
            ] + values.map {
                "\(indent)    \($0)"
            }

        case .event(let value):
            return [
                "\(indent)event: \(value)",
            ]

        case .diff(
            let title,
            let value
        ):
            var lines = title.isEmpty
                ? []
                : [
                    "\(indent)\(title)",
                ]

            lines.append(
                contentsOf: indentedLines(
                    value,
                    indent: "\(indent)    "
                )
            )

            return lines

        case .table(
            let title,
            let table
        ):
            var lines = title.isEmpty
                ? []
                : [
                    "\(indent)\(title)",
                ]

            if !table.columns.isEmpty {
                lines.append(
                    "\(indent)    \(table.columns.joined(separator: " | "))"
                )
            }

            lines.append(
                contentsOf: table.rows.map {
                    "\(indent)    \($0.joined(separator: " | "))"
                }
            )

            return lines

        case .timeline(
            let title,
            let entries
        ):
            var lines = title.isEmpty
                ? []
                : [
                    "\(indent)\(title)",
                ]

            lines.append(
                contentsOf: entries.map { entry in
                    if let detail = entry.detail {
                        return "\(indent)    \(entry.time) \(entry.name) \(detail)"
                    }

                    return "\(indent)    \(entry.time) \(entry.name)"
                }
            )

            return lines

        case .metric(let metric):
            var value = "\(metric.name): \(metric.value)"

            if let unit = metric.unit {
                value += " \(unit)"
            }

            return [
                "\(indent)\(value)",
            ]

        case .command(let command):
            var lines = [
                "\(indent)command: \(command.command)",
            ]

            if let exitCode = command.exitCode {
                lines.append(
                    "\(indent)exit_code: \(exitCode)"
                )
            }

            if !command.stdout.isEmpty {
                lines.append(
                    "\(indent)stdout:"
                )
                lines.append(
                    contentsOf: indentedLines(
                        command.stdout,
                        indent: "\(indent)    "
                    )
                )
            }

            if !command.stderr.isEmpty {
                lines.append(
                    "\(indent)stderr:"
                )
                lines.append(
                    contentsOf: indentedLines(
                        command.stderr,
                        indent: "\(indent)    "
                    )
                )
            }

            return lines

        case .security(let finding):
            return indentedLines(
                finding.description,
                indent: indent
            )
        }
    }

    func renderMetric(
        _ metric: TestMetric
    ) -> String {
        let value: String

        switch metric.unit {
        case .nanoseconds:
            value = formatNanoseconds(
                Int64(
                    metric.value.rounded()
                )
            )

        case .seconds:
            value = "\(formatScalar(metric.value))s"

        case .count:
            value = "\(formatScalar(metric.value)) count"

        case .bytes:
            value = "\(formatScalar(metric.value)) bytes"

        case .ratio:
            value = "\(formatScalar(metric.value)) ratio"

        case .custom(let unit):
            value = "\(formatScalar(metric.value)) \(unit)"
        }

        return "\(metric.name): \(value)"
    }

    func shortPath(
        _ path: String
    ) -> String {
        guard let rootSuitePath else {
            return path
        }

        if path == rootSuitePath {
            return path
        }

        let prefix = "\(rootSuitePath)/"

        guard path.hasPrefix(
            prefix
        ) else {
            return path
        }

        return String(
            path.dropFirst(
                prefix.count
            )
        )
    }

    func source(
        _ location: TestSourceLocation
    ) -> String {
        let fileName = location.filePath
            .split(
                separator: "/",
                omittingEmptySubsequences: true
            )
            .last
            .map(String.init)
            ?? location.fileID

        return "\(fileName):\(location.line)"
    }

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
            "INT"
        }
    }

    func padded(
        _ value: String,
        to width: Int
    ) -> String {
        guard value.count < width else {
            return value
        }

        return value + String(
            repeating: " ",
            count: width - value.count
        )
    }

    func count(
        _ outcome: TestOutcome,
        in result: TestRunResult
    ) -> Int {
        result.results.count {
            $0.outcome == outcome
        }
    }

    func indentedLines(
        _ value: String,
        indent: String
    ) -> [String] {
        value
            .split(
                separator: "\n",
                omittingEmptySubsequences: false
            )
            .map {
                "\(indent)\($0)"
            }
    }

    func formatDuration(
        _ duration: MonotonicClock.Duration
    ) -> String {
        formatNanoseconds(
            duration.nanoseconds
        )
    }

    func formatNanoseconds(
        _ nanoseconds: Int64
    ) -> String {
        let negative = nanoseconds < 0
        let magnitude = nanoseconds.magnitude

        let body: String

        if magnitude < 1_000 {
            body = "\(magnitude)ns"
        } else if magnitude < 1_000_000 {
            body = scaled(
                magnitude,
                divisor: 1_000,
                unit: "us"
            )
        } else if magnitude < 1_000_000_000 {
            body = scaled(
                magnitude,
                divisor: 1_000_000,
                unit: "ms"
            )
        } else {
            body = scaled(
                magnitude,
                divisor: 1_000_000_000,
                unit: "s"
            )
        }

        return negative
            ? "-\(body)"
            : body
    }

    func scaled(
        _ magnitude: UInt64,
        divisor: UInt64,
        unit: String
    ) -> String {
        let whole = magnitude / divisor
        let remainder = magnitude % divisor
        let thousandths = (
            remainder * 1_000
        ) / divisor

        guard thousandths > 0 else {
            return "\(whole)\(unit)"
        }

        var fraction = String(
            thousandths
        )

        if fraction.count < 3 {
            fraction = String(
                repeating: "0",
                count: 3 - fraction.count
            ) + fraction
        }

        while fraction.last == "0" {
            fraction.removeLast()
        }

        return "\(whole).\(fraction)\(unit)"
    }

    func formatScalar(
        _ value: Double
    ) -> String {
        let rounded = value.rounded()

        if rounded == value,
           rounded >= Double(Int64.min),
           rounded <= Double(Int64.max)
        {
            return String(
                Int64(rounded)
            )
        }

        let thousandths = (
            value * 1_000
        ).rounded() / 1_000

        return String(
            thousandths
        )
    }
}
