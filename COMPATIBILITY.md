# Testing compatibility surface

The preferred standalone Testing API is built around `Test`, `TestSuite`, `TestContext`, `TestRunner`, `TestResult`, `TestIssue`, `TestOutcome`, `TestEventSink`, `TestFixture`, `TestCases`, `TestProperty`, and `TestBenchmark`.

The older `TestFlow*` vocabulary remains available as a compatibility surface while existing TestFlows consumers migrate. It should not be expanded with new generic testing semantics unless compatibility requires it.

`TestFlows` remains the richer integration layer for Terminal presentation, Difference-backed rendering, snapshots, filesystem persistence, CLI behavior, and runtime-specific behavior.
