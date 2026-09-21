import Foundation

public struct TestBenchmarkConfiguration:
    Sendable,
    Hashable
{
    public let warmupIterations: Int
    public let iterations: Int

    public init(
        warmupIterations: Int = 1,
        iterations: Int = 10
    ) {
        precondition(
            warmupIterations >= 0
        )
        precondition(
            iterations > 0
        )

        self.warmupIterations = warmupIterations
        self.iterations = iterations
    }
}

public struct TestBenchmarkSample: Sendable {
    public let duration: TimeInterval
    public let metrics: [String: Double]

    public init(
        duration: TimeInterval,
        metrics: [String: Double] = [:]
    ) {
        self.duration = duration
        self.metrics = metrics
    }
}

public struct TestBenchmarkSummary: Sendable {
    public let samples: [TestBenchmarkSample]
    public let minimum: TimeInterval
    public let maximum: TimeInterval
    public let mean: TimeInterval
    public let median: TimeInterval
    public let p90: TimeInterval
    public let p95: TimeInterval
    public let p99: TimeInterval

    public init(
        samples: [TestBenchmarkSample]
    ) {
        precondition(
            !samples.isEmpty
        )

        self.samples = samples

        let durations = samples
            .map(\.duration)
            .sorted()

        self.minimum = durations[0]
        self.maximum = durations[durations.count - 1]
        self.mean = durations.reduce(
            0,
            +
        ) / Double(durations.count)
        self.median = Self.percentile(
            durations,
            0.5
        )
        self.p90 = Self.percentile(
            durations,
            0.90
        )
        self.p95 = Self.percentile(
            durations,
            0.95
        )
        self.p99 = Self.percentile(
            durations,
            0.99
        )
    }
}

public struct TestBenchmarkMeasurement<Value: Sendable>:
    Sendable
{
    public let value: Value
    public let summary: TestBenchmarkSummary

    public init(
        value: Value,
        summary: TestBenchmarkSummary
    ) {
        self.value = value
        self.summary = summary
    }
}

public struct TestBenchmarkComparison: Sendable {
    public let baseline: TestBenchmarkSummary
    public let candidate: TestBenchmarkSummary

    public init(
        baseline: TestBenchmarkSummary,
        candidate: TestBenchmarkSummary
    ) {
        self.baseline = baseline
        self.candidate = candidate
    }

    public var medianRatio: Double {
        baseline.median / candidate.median
    }
}

public enum TestBenchmark {
    public static func measure<Value: Sendable>(
        configuration: TestBenchmarkConfiguration = .init(),
        operation: @Sendable () throws -> Value,
        metrics: @Sendable (Value) -> [String: Double] = { _ in [:] }
    ) throws -> TestBenchmarkMeasurement<Value> {
        for _ in 0..<configuration.warmupIterations {
            _ = try operation()
        }

        var samples: [TestBenchmarkSample] = []
        samples.reserveCapacity(
            configuration.iterations
        )

        let firstStarted = ProcessInfo.processInfo.systemUptime
        var value = try operation()
        let firstEnded = ProcessInfo.processInfo.systemUptime

        samples.append(
            .init(
                duration: firstEnded - firstStarted,
                metrics: metrics(value)
            )
        )

        if configuration.iterations > 1 {
            for _ in 1..<configuration.iterations {
                let started = ProcessInfo.processInfo.systemUptime
                let current = try operation()
                let ended = ProcessInfo.processInfo.systemUptime

                samples.append(
                    .init(
                        duration: ended - started,
                        metrics: metrics(current)
                    )
                )
                value = current
            }
        }

        return .init(
            value: value,
            summary: .init(
                samples: samples
            )
        )
    }

    public static func measureAsync<Value: Sendable>(
        configuration: TestBenchmarkConfiguration = .init(),
        operation: @Sendable () async throws -> Value,
        metrics: @Sendable (Value) -> [String: Double] = { _ in [:] }
    ) async throws -> TestBenchmarkMeasurement<Value> {
        for _ in 0..<configuration.warmupIterations {
            _ = try await operation()
        }

        var samples: [TestBenchmarkSample] = []
        samples.reserveCapacity(
            configuration.iterations
        )

        let firstStarted = ProcessInfo.processInfo.systemUptime
        var value = try await operation()
        let firstEnded = ProcessInfo.processInfo.systemUptime

        samples.append(
            .init(
                duration: firstEnded - firstStarted,
                metrics: metrics(value)
            )
        )

        if configuration.iterations > 1 {
            for _ in 1..<configuration.iterations {
                let started = ProcessInfo.processInfo.systemUptime
                let current = try await operation()
                let ended = ProcessInfo.processInfo.systemUptime

                samples.append(
                    .init(
                        duration: ended - started,
                        metrics: metrics(current)
                    )
                )
                value = current
            }
        }

        return .init(
            value: value,
            summary: .init(
                samples: samples
            )
        )
    }
}

private extension TestBenchmarkSummary {
    static func percentile(
        _ sorted: [TimeInterval],
        _ percentile: Double
    ) -> TimeInterval {
        precondition(
            !sorted.isEmpty
        )
        precondition(
            percentile >= 0
                && percentile <= 1
        )

        guard sorted.count > 1 else {
            return sorted[0]
        }

        let position = percentile
            * Double(sorted.count - 1)
        let lower = Int(
            position.rounded(.down)
        )
        let upper = Int(
            position.rounded(.up)
        )

        guard lower != upper else {
            return sorted[lower]
        }

        let fraction = position
            - Double(lower)

        return sorted[lower]
            + (
                sorted[upper]
                    - sorted[lower]
            ) * fraction
    }
}
