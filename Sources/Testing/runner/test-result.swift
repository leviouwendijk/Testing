import Atomos

public struct TestDescriptor:
    Sendable,
    Hashable
{
    public let id: String
    public let path: String
    public let displayName: String
    public let tags: Set<String>
    public let sourceLocation: TestSourceLocation

    public init(
        id: String,
        path: String,
        displayName: String,
        tags: Set<String>,
        sourceLocation: TestSourceLocation
    ) {
        self.id = id
        self.path = path
        self.displayName = displayName
        self.tags = tags
        self.sourceLocation = sourceLocation
    }
}

public struct TestResult:
    Sendable,
    Hashable
{
    public let test: TestDescriptor
    public let outcome: TestOutcome
    public let startedAt: Date
    public let endedAt: Date
    public let duration: MonotonicClock.Duration
    public let issues: [TestIssue]
    public let diagnostics: [TestFlowDiagnostic]

    public init(
        test: TestDescriptor,
        outcome: TestOutcome,
        startedAt: Date,
        endedAt: Date,
        duration: MonotonicClock.Duration? = nil,
        issues: [TestIssue] = [],
        diagnostics: [TestFlowDiagnostic] = []
    ) {
        self.test = test
        self.outcome = outcome
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.duration = duration
            ?? .init(
                seconds: endedAt.timeIntervalSince(
                    startedAt
                )
            )
        self.issues = issues
        self.diagnostics = diagnostics
    }

    public var wallClockDuration: TimeInterval {
        endedAt.timeIntervalSince(startedAt)
    }

    public var isFailure: Bool {
        outcome.isFailure
    }
}

public struct TestRunResult:
    Sendable,
    Hashable
{
    public let title: String
    public let startedAt: Date
    public let endedAt: Date
    public let duration: MonotonicClock.Duration
    public let results: [TestResult]

    public init(
        title: String,
        startedAt: Date,
        endedAt: Date,
        duration: MonotonicClock.Duration? = nil,
        results: [TestResult]
    ) {
        self.title = title
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.duration = duration
            ?? .init(
                seconds: endedAt.timeIntervalSince(
                    startedAt
                )
            )
        self.results = results
    }

    public var wallClockDuration: TimeInterval {
        endedAt.timeIntervalSince(startedAt)
    }

    public var failureCount: Int {
        results.count(where: \.isFailure)
    }

    public var passedCount: Int {
        results.count {
            $0.outcome == .passed
                || $0.outcome == .expected_failure
        }
    }

    public var skippedCount: Int {
        results.count {
            $0.outcome == .skipped
        }
    }

    public var isFailure: Bool {
        failureCount > 0
    }
}
