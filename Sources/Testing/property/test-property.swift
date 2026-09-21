public struct TestProperty: Sendable {
    public struct Configuration:
        Sendable,
        Hashable
    {
        public let iterations: Int
        public let seed: UInt64

        public init(
            iterations: Int = 100,
            seed: UInt64 = 0x54455354494E47
        ) {
            precondition(
                iterations > 0
            )

            self.iterations = iterations
            self.seed = seed
        }

        public static let quick = Self(
            iterations: 32
        )

        public static let standard = Self()

        public static let exhaustive = Self(
            iterations: 1_024
        )
    }

    public struct Iteration:
        Sendable,
        Hashable
    {
        public let index: Int
        public let seed: UInt64

        public init(
            index: Int,
            seed: UInt64
        ) {
            self.index = index
            self.seed = seed
        }

        public func random() -> TestRandom {
            .init(
                seed: seed
            )
        }
    }

    public let suite: TestSuite

    public init(
        _ id: String,
        title: String? = nil,
        tags: Set<String> = [],
        configuration: Configuration = .standard,
        sourceLocation: TestSourceLocation = .init(),
        operation: @escaping @Sendable (TestContext, Iteration) async throws -> Void
    ) {
        let iterations = Self.generatedIterations(
            configuration: configuration
        )

        self.suite = TestSuite(
            id,
            title: title,
            tags: tags.union(
                Set(["property"])
            ),
            children: iterations.map { iteration in
                .test(
                    Test(
                        "iteration-\(iteration.index)",
                        title: "seed \(iteration.seed)",
                        tags: [
                            "seed:\(iteration.seed)",
                        ],
                        sourceLocation: sourceLocation
                    ) { context in
                        await context.record(
                            .field(
                                "property_seed",
                                String(iteration.seed)
                            )
                        )
                        await context.record(
                            .field(
                                "property_iteration",
                                String(iteration.index)
                            )
                        )

                        try await operation(
                            context,
                            iteration
                        )
                    }
                )
            }
        )
    }

    public init(
        _ id: String,
        title: String? = nil,
        tags: Set<String> = [],
        iterations: Int,
        seed: UInt64 = 0x54455354494E47,
        sourceLocation: TestSourceLocation = .init(),
        operation: @escaping @Sendable (TestContext, Iteration) async throws -> Void
    ) {
        self.init(
            id,
            title: title,
            tags: tags,
            configuration: .init(
                iterations: iterations,
                seed: seed
            ),
            sourceLocation: sourceLocation,
            operation: operation
        )
    }

    public static func make(
        _ id: String,
        title: String? = nil,
        tags: Set<String> = [],
        iterations: Int = 100,
        seed: UInt64 = 0x54455354494E47,
        sourceLocation: TestSourceLocation = .init(),
        operation: @escaping @Sendable (TestContext, Iteration) async throws -> Void
    ) -> TestSuite {
        Self(
            id,
            title: title,
            tags: tags,
            configuration: .init(
                iterations: iterations,
                seed: seed
            ),
            sourceLocation: sourceLocation,
            operation: operation
        ).suite
    }

    public static func makeSynchronous(
        _ id: String,
        title: String? = nil,
        tags: Set<String> = [],
        iterations: Int = 100,
        seed: UInt64 = 0x54455354494E47,
        sourceLocation: TestSourceLocation = .init(),
        operation: @escaping @Sendable (inout TestRandom) throws -> Void
    ) -> TestSuite {
        Self.make(
            id,
            title: title,
            tags: tags,
            iterations: iterations,
            seed: seed,
            sourceLocation: sourceLocation
        ) { _, iteration in
            var random = iteration.random()
            try operation(
                &random
            )
        }
    }
}

public typealias TestPropertyConfiguration = TestProperty.Configuration
public typealias TestPropertyIteration = TestProperty.Iteration

private extension TestProperty {
    static func generatedIterations(
        configuration: Configuration
    ) -> [Iteration] {
        var random = TestRandom(
            seed: configuration.seed
        )
        var iterations: [Iteration] = []
        iterations.reserveCapacity(
            configuration.iterations
        )

        for index in 0..<configuration.iterations {
            iterations.append(
                .init(
                    index: index,
                    seed: random.nextUInt64()
                )
            )
        }

        return iterations
    }
}
