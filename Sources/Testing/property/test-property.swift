public struct TestPropertyIteration:
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

public enum TestProperty {
    public static func make(
        _ id: String,
        title: String? = nil,
        tags: Set<String> = [],
        iterations: Int = 100,
        seed: UInt64 = 0x54455354494E47,
        sourceLocation: TestSourceLocation = .init(),
        operation: @escaping @Sendable (TestContext, TestPropertyIteration) async throws -> Void
    ) -> TestSuite {
        precondition(
            iterations > 0
        )

        let cases = generatedIterations(
            count: iterations,
            seed: seed
        )

        return TestSuite(
            id,
            title: title,
            tags: tags.union(
                Set(["property"])
            ),
            children: cases.map { iteration in
                .test(
                    Test(
                        "iteration-\(iteration.index)",
                        title: "seed \(iteration.seed)",
                        tags: [
                            "seed:\(iteration.seed)",
                        ],
                        sourceLocation: sourceLocation
                    ) { context in
                        do {
                            try await operation(
                                context,
                                iteration
                            )
                        } catch {
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

                            throw error
                        }
                    }
                )
            }
        )
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
        make(
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

private extension TestProperty {
    static func generatedIterations(
        count: Int,
        seed: UInt64
    ) -> [TestPropertyIteration] {
        var random = TestRandom(
            seed: seed
        )
        var iterations: [TestPropertyIteration] = []
        iterations.reserveCapacity(count)

        for index in 0..<count {
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
