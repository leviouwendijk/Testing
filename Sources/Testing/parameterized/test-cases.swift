public struct TestCases<Value: Sendable>: Sendable {
    public let suite: TestSuite

    public init(
        _ id: String,
        title: String? = nil,
        tags: Set<String> = [],
        values: [Value],
        name: @escaping @Sendable (Value) -> String = {
            String(describing: $0)
        },
        sourceLocation: TestSourceLocation = TestSourceLocation(fileID: #fileID, filePath: #filePath, line: #line, column: #column),
        operation: @escaping @Sendable (TestContext, Value) async throws -> Void
    ) {
        self.suite = TestSuite(
            id,
            title: title,
            tags: tags.union(
                Set(["cases"])
            ),
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

    public static func make(
        _ id: String,
        title: String? = nil,
        tags: Set<String> = [],
        values: [Value],
        name: @escaping @Sendable (Value) -> String = {
            String(describing: $0)
        },
        sourceLocation: TestSourceLocation = TestSourceLocation(fileID: #fileID, filePath: #filePath, line: #line, column: #column),
        operation: @escaping @Sendable (TestContext, Value) async throws -> Void
    ) -> TestSuite {
        Self(
            id,
            title: title,
            tags: tags,
            values: values,
            name: name,
            sourceLocation: sourceLocation,
            operation: operation
        ).suite
    }
}
