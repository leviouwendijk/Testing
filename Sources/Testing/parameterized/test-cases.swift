public enum TestCases {
    public static func make<Value: Sendable>(
        _ id: String,
        title: String? = nil,
        tags: Set<String> = [],
        values: [Value],
        name: @escaping @Sendable (Value) -> String,
        sourceLocation: TestSourceLocation = .init(),
        operation: @escaping @Sendable (TestContext, Value) async throws -> Void
    ) -> TestSuite {
        TestSuite(
            id,
            title: title,
            tags: tags,
            children: values.enumerated().map { index, value in
                .test(
                    Test(
                        "case-\(index)",
                        title: name(value),
                        sourceLocation: sourceLocation
                    ) { context in
                        try await operation(
                            context,
                            value
                        )
                    }
                )
            }
        )
    }
}
