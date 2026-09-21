import Foundation
import Atomos

public enum TestRunner {
    public static func run(
        _ suite: TestSuite,
        configuration: TestRunConfiguration = .default,
        sink: any TestEventSink = NullTestEventSink()
    ) async -> TestRunResult {
        let clock = MonotonicClock()
        let monotonicStartedAt = clock.now
        let startedAt = Date()
        let totalTests = selectedTestCount(
            in: suite,
            inheritedTags: [],
            parentPath: [],
            selection: configuration.selection
        )

        await sink.receive(
            .run_started(
                title: suite.title,
                totalTests: totalTests
            )
        )

        let output = await runSuite(
            suite,
            inheritedTags: [],
            inheritedSkipReason: nil,
            parentPath: [],
            configuration: configuration,
            sink: sink
        )

        let result = TestRunResult(
            title: suite.title,
            startedAt: startedAt,
            endedAt: Date(),
            duration: monotonicStartedAt.duration(
                to: clock.now
            ),
            results: output.results
        )

        await sink.receive(
            .run_finished(result)
        )

        return result
    }
}

private extension TestRunner {
    struct SuiteRunOutput {
        let results: [TestResult]
        let stopped: Bool
    }

    static func selectedTestCount(
        in suite: TestSuite,
        inheritedTags: Set<String>,
        parentPath: [String],
        selection: TestSelection
    ) -> Int {
        let suiteTags = inheritedTags.union(
            suite.tags
        )
        let suitePath = parentPath + [suite.id]

        return suite.children.reduce(
            into: 0
        ) { count, node in
            switch node {
            case .test(let test):
                let tags = suiteTags.union(
                    test.tags
                )
                let path = (
                    suitePath + [test.id]
                ).joined(
                    separator: "/"
                )

                if selection.accepts(
                    path: path,
                    name: test.id,
                    displayName: test.displayName,
                    tags: tags
                ) {
                    count += 1
                }

            case .suite(let nested):
                count += selectedTestCount(
                    in: nested,
                    inheritedTags: suiteTags,
                    parentPath: suitePath,
                    selection: selection
                )
            }
        }
    }

    static func runSuite(
        _ suite: TestSuite,
        inheritedTags: Set<String>,
        inheritedSkipReason: String?,
        parentPath: [String],
        configuration: TestRunConfiguration,
        sink: any TestEventSink
    ) async -> SuiteRunOutput {
        let suiteTags = inheritedTags.union(
            suite.tags
        )
        let effectiveSkipReason = inheritedSkipReason
            ?? suite.skipReason
        let suitePathComponents = parentPath + [
            suite.id
        ]
        let suitePath = suitePathComponents.joined(
            separator: "/"
        )

        let selectedCount = selectedTestCount(
            in: suite,
            inheritedTags: inheritedTags,
            parentPath: parentPath,
            selection: configuration.selection
        )

        guard selectedCount > 0 else {
            return .init(
                results: [],
                stopped: false
            )
        }

        let descriptor = TestSuiteDescriptor(
            id: suite.id,
            path: suitePath,
            title: suite.title,
            tags: suiteTags
        )

        await sink.receive(
            .suite_started(descriptor)
        )

        var results: [TestResult] = []
        var stopped = false

        for node in suite.children {
            switch node {
            case .test(let test):
                let tags = suiteTags.union(
                    test.tags
                )
                let path = (
                    suitePathComponents + [test.id]
                ).joined(
                    separator: "/"
                )

                guard configuration.selection.accepts(
                    path: path,
                    name: test.id,
                    displayName: test.displayName,
                    tags: tags
                ) else {
                    continue
                }

                let result = await runTest(
                    test,
                    path: path,
                    tags: tags,
                    inheritedSkipReason: effectiveSkipReason,
                    sink: sink
                )

                results.append(result)

                if configuration.failFast,
                   result.isFailure {
                    stopped = true
                }

            case .suite(let nested):
                let nestedOutput = await runSuite(
                    nested,
                    inheritedTags: suiteTags,
                    inheritedSkipReason: effectiveSkipReason,
                    parentPath: suitePathComponents,
                    configuration: configuration,
                    sink: sink
                )

                results.append(
                    contentsOf: nestedOutput.results
                )
                stopped = nestedOutput.stopped
            }

            if stopped {
                break
            }
        }

        await sink.receive(
            .suite_finished(
                descriptor,
                resultCount: results.count
            )
        )

        return .init(
            results: results,
            stopped: stopped
        )
    }

    static func runTest(
        _ test: Test,
        path: String,
        tags: Set<String>,
        inheritedSkipReason: String?,
        sink: any TestEventSink
    ) async -> TestResult {
        let descriptor = TestDescriptor(
            id: test.id,
            path: path,
            displayName: test.displayName,
            tags: tags,
            sourceLocation: test.sourceLocation
        )

        await sink.receive(
            .test_started(descriptor)
        )

        let clock = MonotonicClock()
        let monotonicStartedAt = clock.now
        let startedAt = Date()
        let recorder = TestRecorder()
        let context = TestContext(
            recorder: recorder
        )

        var outcome: TestOutcome = .passed
        var immediateDiagnostics: [TestFlowDiagnostic] = []

        if let skipReason = inheritedSkipReason
            ?? test.skipReason {
            outcome = .skipped
            immediateDiagnostics = [
                .field(
                    "reason",
                    skipReason
                )
            ]
        } else {
            do {
                try await test.operation(context)
            } catch let skip as TestFlowSkip {
                outcome = .skipped
                immediateDiagnostics = skip.testFlowDiagnostics
            } catch let requirement as TestRequirementFailure {
                await recorder.record(
                    requirement.issue
                )
            } catch let assertion as TestFlowAssertionFailure {
                await recorder.record(
                    TestIssue(
                        kind: .expectation,
                        message: "\(assertion.label): \(assertion.message)",
                        sourceLocation: assertion.sourceLocation
                            ?? test.sourceLocation,
                        actual: assertion.actual,
                        expected: assertion.expected,
                        diagnostics: assertion.diagnostics
                    )
                )
            } catch {
                await recorder.record(
                    TestIssue(
                        kind: .error,
                        message: String(
                            describing: error
                        ),
                        sourceLocation: test.sourceLocation,
                        diagnostics: TestFlowErrorDiagnostics.diagnostics(
                            for: error
                        )
                    )
                )
            }
        }

        let recording = await recorder.snapshot()

        if outcome == .passed,
           !recording.issues.isEmpty {
            outcome = .failed
        }

        var diagnostics = immediateDiagnostics
            + recording.diagnostics

        if let expectedFailure = test.expectedFailure {
            switch outcome {
            case .failed:
                outcome = .expected_failure
                diagnostics.append(
                    .field(
                        "expected_failure",
                        expectedFailure
                    )
                )

            case .passed:
                outcome = .unexpected_pass
                diagnostics.append(
                    .field(
                        "expected_failure",
                        expectedFailure
                    )
                )

            case .skipped,
                 .expected_failure,
                 .unexpected_pass,
                 .interrupted:
                break
            }
        }

        let result = TestResult(
            test: descriptor,
            outcome: outcome,
            startedAt: startedAt,
            endedAt: Date(),
            duration: monotonicStartedAt.duration(
                to: clock.now
            ),
            issues: recording.issues,
            diagnostics: diagnostics
        )

        for issue in recording.issues {
            await sink.receive(
                .issue_recorded(
                    issue,
                    test: descriptor
                )
            )
        }

        for diagnostic in diagnostics {
            await sink.receive(
                .diagnostic_recorded(
                    diagnostic,
                    test: descriptor
                )
            )
        }

        await sink.receive(
            .test_finished(result)
        )

        return result
    }
}
