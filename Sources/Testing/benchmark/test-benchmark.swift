import Atomos

public struct TestBenchmark: Sendable {
    public struct Configuration:
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

        public static let quick = Self(
            warmupIterations: 0,
            iterations: 3
        )

        public static let standard = Self()

        public static let heavy = Self(
            warmupIterations: 3,
            iterations: 100
        )
    }

    public struct Sample: Sendable {
        public let duration: MonotonicClock.Duration
        public let metrics: [String: Double]

        public init(
            duration: MonotonicClock.Duration,
            metrics: [String: Double] = [:]
        ) {
            self.duration = duration
            self.metrics = metrics
        }
    }

    public struct Summary: Sendable {
        public let samples: [Sample]
        public let minimum: MonotonicClock.Duration
        public let maximum: MonotonicClock.Duration
        public let mean: MonotonicClock.Duration
        public let median: MonotonicClock.Duration
        public let p90: MonotonicClock.Duration
        public let p95: MonotonicClock.Duration
        public let p99: MonotonicClock.Duration

        public init(
            samples: [Sample]
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

            let meanNanoseconds = durations.reduce(
                0.0
            ) { partial, duration in
                partial + Double(duration.nanoseconds)
            } / Double(durations.count)

            self.mean = .init(
                nanoseconds: Int64(
                    meanNanoseconds.rounded()
                )
            )
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

    public struct Measurement<Value: Sendable>:
        Sendable
    {
        public let value: Value
        public let summary: Summary

        public init(
            value: Value,
            summary: Summary
        ) {
            self.value = value
            self.summary = summary
        }
    }

    public struct Comparison: Sendable {
        public let baseline: Summary
        public let candidate: Summary

        public init(
            baseline: Summary,
            candidate: Summary
        ) {
            self.baseline = baseline
            self.candidate = candidate
        }

        public var medianRatio: Double {
            guard candidate.median.nanoseconds != 0 else {
                return .infinity
            }

            return Double(baseline.median.nanoseconds)
                / Double(candidate.median.nanoseconds)
        }
    }

    let test: Test

    public init(
        _ id: String,
        title: String? = nil,
        tags: Set<String> = [],
        configuration: Configuration = .standard,
        sourceLocation: TestSourceLocation? = nil,
        fileID: String = #fileID,
        filePath: String = #filePath,
        line: UInt = #line,
        column: UInt = #column,
        operation: @escaping @Sendable () async throws -> Void
    ) {
        let sourceLocation = sourceLocation ?? TestSourceLocation(
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
        )

        self.test = Test(
            id,
            title: title,
            tags: tags.union(
                Set(["benchmark"])
            ),
            sourceLocation: sourceLocation
        ) { context in
            let measurement = try await Self.measureAsync(
                configuration: configuration
            ) {
                try await operation()
                return true
            }

            await Self.record(
                measurement.summary,
                in: context
            )
        }
    }

    public init(
        _ id: String,
        title: String? = nil,
        tags: Set<String> = [],
        configuration: Configuration = .standard,
        sourceLocation: TestSourceLocation? = nil,
        fileID: String = #fileID,
        filePath: String = #filePath,
        line: UInt = #line,
        column: UInt = #column,
        sync operation: @escaping @Sendable () throws -> Void
    ) {
        let sourceLocation = sourceLocation ?? TestSourceLocation(
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
        )

        self.test = Test(
            id,
            title: title,
            tags: tags.union(
                Set(["benchmark"])
            ),
            sourceLocation: sourceLocation
        ) { context in
            let measurement = try Self.measure(
                configuration: configuration
            ) {
                try operation()
                return true
            }

            await Self.record(
                measurement.summary,
                in: context
            )
        }
    }

    public static func measure<Value: Sendable>(
        configuration: Configuration = .standard,
        operation: @Sendable () throws -> Value,
        metrics: @Sendable (Value) -> [String: Double] = { _ in [:] }
    ) throws -> Measurement<Value> {
        for _ in 0..<configuration.warmupIterations {
            _ = try operation()
        }

        let clock = MonotonicClock()
        var samples: [Sample] = []
        samples.reserveCapacity(
            configuration.iterations
        )

        let firstStarted = clock.now
        var value = try operation()
        let firstDuration = firstStarted.duration(
            to: clock.now
        )

        samples.append(
            .init(
                duration: firstDuration,
                metrics: metrics(value)
            )
        )

        if configuration.iterations > 1 {
            for _ in 1..<configuration.iterations {
                let started = clock.now
                let current = try operation()
                let duration = started.duration(
                    to: clock.now
                )

                samples.append(
                    .init(
                        duration: duration,
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
        configuration: Configuration = .standard,
        operation: @Sendable () async throws -> Value,
        metrics: @Sendable (Value) -> [String: Double] = { _ in [:] }
    ) async throws -> Measurement<Value> {
        for _ in 0..<configuration.warmupIterations {
            _ = try await operation()
        }

        let clock = MonotonicClock()
        var samples: [Sample] = []
        samples.reserveCapacity(
            configuration.iterations
        )

        let firstStarted = clock.now
        var value = try await operation()
        let firstDuration = firstStarted.duration(
            to: clock.now
        )

        samples.append(
            .init(
                duration: firstDuration,
                metrics: metrics(value)
            )
        )

        if configuration.iterations > 1 {
            for _ in 1..<configuration.iterations {
                let started = clock.now
                let current = try await operation()
                let duration = started.duration(
                    to: clock.now
                )

                samples.append(
                    .init(
                        duration: duration,
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

public typealias TestBenchmarkConfiguration = TestBenchmark.Configuration
public typealias TestBenchmarkSample = TestBenchmark.Sample
public typealias TestBenchmarkSummary = TestBenchmark.Summary
public typealias TestBenchmarkMeasurement<Value: Sendable> = TestBenchmark.Measurement<Value>
public typealias TestBenchmarkComparison = TestBenchmark.Comparison

private extension TestBenchmark {
    static func record(
        _ summary: Summary,
        in context: TestContext
    ) async {
        await context.record(
            TestMetric(
                "benchmark.minimum",
                value: Double(summary.minimum.nanoseconds),
                unit: .nanoseconds
            )
        )
        await context.record(
            TestMetric(
                "benchmark.mean",
                value: Double(summary.mean.nanoseconds),
                unit: .nanoseconds
            )
        )
        await context.record(
            TestMetric(
                "benchmark.median",
                value: Double(summary.median.nanoseconds),
                unit: .nanoseconds
            )
        )
        await context.record(
            TestMetric(
                "benchmark.p90",
                value: Double(summary.p90.nanoseconds),
                unit: .nanoseconds
            )
        )
        await context.record(
            TestMetric(
                "benchmark.p95",
                value: Double(summary.p95.nanoseconds),
                unit: .nanoseconds
            )
        )
        await context.record(
            TestMetric(
                "benchmark.p99",
                value: Double(summary.p99.nanoseconds),
                unit: .nanoseconds
            )
        )
        await context.record(
            TestMetric(
                "benchmark.maximum",
                value: Double(summary.maximum.nanoseconds),
                unit: .nanoseconds
            )
        )
    }
}

private extension TestBenchmark.Summary {
    static func percentile(
        _ sorted: [MonotonicClock.Duration],
        _ percentile: Double
    ) -> MonotonicClock.Duration {
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
        let lowerNanoseconds = Double(
            sorted[lower].nanoseconds
        )
        let upperNanoseconds = Double(
            sorted[upper].nanoseconds
        )

        return .init(
            nanoseconds: Int64(
                (
                    lowerNanoseconds
                        + (
                            upperNanoseconds
                                - lowerNanoseconds
                        ) * fraction
                ).rounded()
            )
        )
    }
}
