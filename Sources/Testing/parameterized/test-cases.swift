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
        sourceLocation: TestSourceLocation? = nil,
        fileID: String = #fileID,
        filePath: String = #filePath,
        line: UInt = #line,
        column: UInt = #column,
        operation: @escaping @Sendable (TestContext, Value) async throws -> Void
    ) {
        let sourceLocation = sourceLocation ?? TestSourceLocation(
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
        )

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
        sourceLocation: TestSourceLocation? = nil,
        fileID: String = #fileID,
        filePath: String = #filePath,
        line: UInt = #line,
        column: UInt = #column,
        operation: @escaping @Sendable (TestContext, Value) async throws -> Void
    ) -> TestSuite {
        Self(
            id,
            title: title,
            tags: tags,
            values: values,
            name: name,
            sourceLocation: sourceLocation,
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column,
            operation: operation
        ).suite
    }
}
