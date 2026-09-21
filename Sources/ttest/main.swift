import Testing

private struct CharacterizationFailure:
    Error,
    CustomStringConvertible
{
    let message: String

    var description: String {
        message
    }
}

private struct ProbeFailure: Error {}

private actor CaptureSink: TestEventSink {
    private var labels: [String] = []

    func receive(
        _ event: TestExecutionEvent
    ) async {
        labels.append(
            Self.label(event)
        )
    }

    func snapshot() -> [String] {
        labels
    }

    private static func label(
        _ event: TestExecutionEvent
    ) -> String {
        switch event {
        case .run_started:
            "run_started"

        case .suite_started(let suite):
            "suite_started:\(suite.path)"

        case .test_started(let test):
            "test_started:\(test.path)"

        case .issue_recorded(_, let test):
            "issue_recorded:\(test.path)"

        case .diagnostic_recorded(_, let test):
            "diagnostic_recorded:\(test.path)"

        case .metric_recorded(_, let test):
            "metric_recorded:\(test.path)"

        case .test_finished(let result):
            "test_finished:\(result.test.path)"

        case .suite_finished(let suite, _):
            "suite_finished:\(suite.path)"

        case .run_finished:
            "run_finished"
        }
    }
}

@main
private struct TestingCharacterization {
    static func main() async throws {
        try await characterizeSourceLocations()
        try await characterizePropertyDiagnostics()
        try await characterizeLiveEvents()
        try await characterizeCompositeSink()
        try await characterizeOutcomesAndFailFast()
        try await characterizeBenchmarkMetrics()

        print("ttest: 6/6 passed")
    }

    private static func characterizeSourceLocations() async throws {
        let directExpectedLine = #line + 1
        let direct = Test("direct-source") {}

        try check(
            direct.sourceLocation.line == directExpectedLine,
            "Test source location did not capture its authoring line"
        )

        let casesExpectedLine = #line + 1
        let cases = TestCases(
            "cases-source",
            values: [1]
        ) { _, _ in }

        let casesResult = await TestRunner.run(
            cases.suite
        )

        try check(
            casesResult.results.count == 1,
            "TestCases characterization did not produce one result"
        )
        try check(
            casesResult.results[0].test.sourceLocation.line
                == casesExpectedLine,
            "TestCases source location did not capture its authoring line"
        )

        let propertyExpectedLine = #line + 1
        let property = TestProperty(
            "property-source",
            iterations: 1
        ) { _, _ in }

        let propertyResult = await TestRunner.run(
            property.suite
        )

        try check(
            propertyResult.results.count == 1,
            "TestProperty characterization did not produce one result"
        )
        try check(
            propertyResult.results[0].test.sourceLocation.line
                == propertyExpectedLine,
            "TestProperty source location did not capture its authoring line"
        )

        let benchmarkExpectedLine = #line + 1
        let benchmark = TestBenchmark(
            "benchmark-source",
            configuration: .quick,
            sync: {}
        )
        let benchmarkSuite = TestSuite(
            "benchmark-source-suite"
        ) {
            benchmark
        }
        let benchmarkResult = await TestRunner.run(
            benchmarkSuite
        )

        try check(
            benchmarkResult.results.count == 1,
            "TestBenchmark characterization did not produce one result"
        )
        try check(
            benchmarkResult.results[0].test.sourceLocation.line
                == benchmarkExpectedLine,
            "TestBenchmark source location did not capture its authoring line"
        )

        print("ttest: source locations passed")
    }

    private static func characterizePropertyDiagnostics() async throws {
        let success = TestProperty(
            "property-success",
            iterations: 1,
            seed: 42
        ) { _, _ in }

        let successResult = await TestRunner.run(
            success.suite
        )

        try check(
            successResult.results.count == 1,
            "successful property did not produce one result"
        )
        try check(
            !hasField(
                "property_seed",
                in: successResult.results[0].diagnostics
            ),
            "successful property leaked property_seed diagnostic"
        )
        try check(
            !hasField(
                "property_iteration",
                in: successResult.results[0].diagnostics
            ),
            "successful property leaked property_iteration diagnostic"
        )

        let failure = TestProperty(
            "property-failure",
            iterations: 1,
            seed: 42
        ) { _, _ in
            throw ProbeFailure()
        }

        let failureResult = await TestRunner.run(
            failure.suite
        )

        try check(
            failureResult.results.count == 1,
            "failing property did not produce one result"
        )
        try check(
            failureResult.results[0].outcome == .failed,
            "failing property did not fail"
        )
        try check(
            hasField(
                "property_seed",
                in: failureResult.results[0].diagnostics
            ),
            "failing property did not retain property_seed"
        )
        try check(
            hasField(
                "property_iteration",
                in: failureResult.results[0].diagnostics
            ),
            "failing property did not retain property_iteration"
        )

        print("ttest: property diagnostics passed")
    }

    private static func characterizeLiveEvents() async throws {
        let sink = CaptureSink()

        let suite = TestSuite(
            "live-events"
        ) {
            Test("observed") { context in
                await context.record(
                    .message("live")
                )
                await context.record(
                    TestMetric(
                        "items",
                        value: 1,
                        unit: .count
                    )
                )
                await context.expect(
                    false,
                    "expected characterization issue"
                )
            }
        }

        let result = await TestRunner.run(
            suite,
            sink: sink
        )
        let events = await sink.snapshot()

        try check(
            result.results.count == 1,
            "live event suite did not produce one result"
        )
        try check(
            result.results[0].diagnostics.count == 1,
            "live diagnostic was not persisted exactly once"
        )
        try check(
            result.results[0].metrics.count == 1,
            "live metric was not persisted exactly once"
        )
        try check(
            result.results[0].issues.count == 1,
            "live issue was not persisted exactly once"
        )

        let path = "live-events/observed"
        let started = "test_started:\(path)"
        let diagnostic = "diagnostic_recorded:\(path)"
        let metric = "metric_recorded:\(path)"
        let issue = "issue_recorded:\(path)"
        let finished = "test_finished:\(path)"

        try check(
            count(started, in: events) == 1,
            "test_started was not emitted exactly once"
        )
        try check(
            count(diagnostic, in: events) == 1,
            "diagnostic_recorded was not emitted exactly once"
        )
        try check(
            count(metric, in: events) == 1,
            "metric_recorded was not emitted exactly once"
        )
        try check(
            count(issue, in: events) == 1,
            "issue_recorded was not emitted exactly once"
        )
        try check(
            count(finished, in: events) == 1,
            "test_finished was not emitted exactly once"
        )

        try check(
            index(of: started, in: events)
                < index(of: diagnostic, in: events),
            "diagnostic was emitted before test_started"
        )
        try check(
            index(of: diagnostic, in: events)
                < index(of: metric, in: events),
            "metric ordering did not reflect record order"
        )
        try check(
            index(of: metric, in: events)
                < index(of: issue, in: events),
            "issue ordering did not reflect record order"
        )
        try check(
            index(of: issue, in: events)
                < index(of: finished, in: events),
            "test_finished arrived before live observations"
        )

        print("ttest: live events passed")
    }

    private static func characterizeCompositeSink() async throws {
        let first = CaptureSink()
        let second = CaptureSink()
        let sink = TestCompositeEventSink(
            first,
            second
        )

        let suite = TestSuite(
            "composite"
        ) {
            Test("child") { context in
                await context.record(
                    .message("composite")
                )
            }
        }

        _ = await TestRunner.run(
            suite,
            sink: sink
        )

        let firstEvents = await first.snapshot()
        let secondEvents = await second.snapshot()

        try check(
            firstEvents == secondEvents,
            "composite sink did not forward identical event sequences"
        )
        try check(
            !firstEvents.isEmpty,
            "composite sink received no events"
        )

        print("ttest: composite sink passed")
    }

    private static func characterizeOutcomesAndFailFast() async throws {
        let expectedFailure = TestSuite(
            "xfail-suite"
        ) {
            Test("known") { context in
                await context.expect(
                    false,
                    "known failure"
                )
            }
            .expectedFailure("characterized")
        }

        let expectedFailureResult = await TestRunner.run(
            expectedFailure
        )

        try check(
            expectedFailureResult.results.count == 1,
            "expected-failure suite did not produce one result"
        )
        try check(
            expectedFailureResult.results[0].outcome
                == .expected_failure,
            "expected failure was not classified as expected_failure"
        )

        let skipped = TestSuite(
            "skip-suite"
        ) {
            Test("child") {}
        }
        .skipped("maintenance")

        let skippedResult = await TestRunner.run(
            skipped
        )

        try check(
            skippedResult.results.count == 1,
            "skipped suite did not produce one child result"
        )
        try check(
            skippedResult.results[0].outcome == .skipped,
            "suite skip did not propagate to child"
        )
        try check(
            hasField(
                "reason",
                value: "maintenance",
                in: skippedResult.results[0].diagnostics
            ),
            "suite skip reason was not retained"
        )

        let failFast = TestSuite(
            "fail-fast"
        ) {
            Test("first") { context in
                await context.expect(
                    false,
                    "stop here"
                )
            }

            Test("second") {}
        }

        let failFastResult = await TestRunner.run(
            failFast,
            configuration: .fail_fast
        )

        try check(
            failFastResult.results.count == 1,
            "fail-fast executed tests after the first failure"
        )
        try check(
            failFastResult.results[0].test.id == "first",
            "fail-fast retained the wrong result"
        )

        print("ttest: outcomes and fail-fast passed")
    }

    private static func characterizeBenchmarkMetrics() async throws {
        let sink = CaptureSink()

        let suite = TestSuite(
            "benchmark"
        ) {
            TestBenchmark(
                "work",
                configuration: .quick,
                sync: {
                    _ = 1 + 1
                }
            )
        }

        let result = await TestRunner.run(
            suite,
            sink: sink
        )
        let events = await sink.snapshot()

        try check(
            result.results.count == 1,
            "benchmark suite did not produce one result"
        )

        let metrics = result.results[0].metrics
        let expectedNames: Set<String> = [
            "benchmark.minimum",
            "benchmark.mean",
            "benchmark.median",
            "benchmark.p90",
            "benchmark.p95",
            "benchmark.p99",
            "benchmark.maximum",
        ]

        try check(
            Set(metrics.map(\.name)) == expectedNames,
            "benchmark did not persist the expected typed metrics"
        )
        try check(
            metrics.allSatisfy {
                $0.unit == .nanoseconds
            },
            "benchmark metrics did not retain nanosecond units"
        )

        let metricEventCount = events.count {
            $0 == "metric_recorded:benchmark/work"
        }

        try check(
            metricEventCount == expectedNames.count,
            "benchmark metric events were missing or duplicated"
        )

        print("ttest: benchmark metrics passed")
    }

    private static func check(
        _ condition: @autoclosure () -> Bool,
        _ message: String
    ) throws {
        guard condition() else {
            throw CharacterizationFailure(
                message: message
            )
        }
    }

    private static func count(
        _ label: String,
        in events: [String]
    ) -> Int {
        events.count {
            $0 == label
        }
    }

    private static func index(
        of label: String,
        in events: [String]
    ) -> Int {
        events.firstIndex(
            of: label
        ) ?? .max
    }

    private static func hasField(
        _ name: String,
        value expectedValue: String? = nil,
        in diagnostics: [TestDiagnostic]
    ) -> Bool {
        diagnostics.contains { diagnostic in
            guard case .field(
                let field,
                let value
            ) = diagnostic,
            field == name else {
                return false
            }

            if let expectedValue {
                return value == expectedValue
            }

            return true
        }
    }
}
