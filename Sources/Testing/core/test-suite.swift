public indirect enum TestNode: Sendable {
    case test(Test)
    case suite(TestSuite)
}

@resultBuilder
public enum TestNodeBuilder {
    public static func buildBlock(
        _ components: [TestNode]...
    ) -> [TestNode] {
        components.flatMap { $0 }
    }

    public static func buildExpression(
        _ expression: Test
    ) -> [TestNode] {
        [.test(expression)]
    }

    public static func buildExpression(
        _ expression: TestSuite
    ) -> [TestNode] {
        [.suite(expression)]
    }

    public static func buildExpression<Value: Sendable>(
        _ expression: TestCases<Value>
    ) -> [TestNode] {
        [.suite(expression.suite)]
    }

    public static func buildExpression(
        _ expression: TestProperty
    ) -> [TestNode] {
        [.suite(expression.suite)]
    }

    public static func buildExpression(
        _ expression: TestBenchmark
    ) -> [TestNode] {
        [.test(expression.test)]
    }

    public static func buildExpression(
        _ expression: TestNode
    ) -> [TestNode] {
        [expression]
    }

    public static func buildExpression(
        _ expression: [TestNode]
    ) -> [TestNode] {
        expression
    }

    public static func buildOptional(
        _ component: [TestNode]?
    ) -> [TestNode] {
        component ?? []
    }

    public static func buildEither(
        first component: [TestNode]
    ) -> [TestNode] {
        component
    }

    public static func buildEither(
        second component: [TestNode]
    ) -> [TestNode] {
        component
    }

    public static func buildArray(
        _ components: [[TestNode]]
    ) -> [TestNode] {
        components.flatMap { $0 }
    }
}

public struct TestSuite:
    Sendable,
    Identifiable
{
    public let id: String
    public let title: String
    public let tags: Set<String>
    public let skipReason: String?
    public let children: [TestNode]

    public init(
        _ id: String,
        title: String? = nil,
        tags: Set<String> = [],
        skip: String? = nil,
        children: [TestNode]
    ) {
        self.id = id
        self.title = title ?? id
        self.tags = tags
        self.skipReason = skip
        self.children = children
    }

    public init(
        _ id: String,
        title: String? = nil,
        tags: Set<String> = [],
        skip: String? = nil,
        @TestNodeBuilder children: () -> [TestNode]
    ) {
        self.init(
            id,
            title: title,
            tags: tags,
            skip: skip,
            children: children()
        )
    }

    public init<Registry: TestFlowRegistry>(
        _ registry: Registry.Type,
        id: String? = nil,
        tags: Set<String> = []
    ) {
        self.init(
            id ?? String(describing: Registry.self),
            title: Registry.title,
            tags: tags,
            children: Registry.flows.map {
                .test(
                    Test($0)
                )
            }
        )
    }
}

public extension TestSuite {
    func named(
        _ title: String
    ) -> Self {
        .init(
            id,
            title: title,
            tags: tags,
            skip: skipReason,
            children: children
        )
    }

    func tagged(
        _ tags: String...
    ) -> Self {
        tagged(
            Set(tags)
        )
    }

    func tagged(
        _ additionalTags: Set<String>
    ) -> Self {
        .init(
            id,
            title: title,
            tags: tags.union(additionalTags),
            skip: skipReason,
            children: children
        )
    }

    func skipped(
        _ reason: String
    ) -> Self {
        .init(
            id,
            title: title,
            tags: tags,
            skip: reason,
            children: children
        )
    }

    func disabled(
        when condition: Bool,
        reason: String
    ) -> Self {
        condition
            ? skipped(reason)
            : self
    }
}

public struct TestSuiteDescriptor:
    Sendable,
    Hashable
{
    public let id: String
    public let path: String
    public let title: String
    public let tags: Set<String>

    public init(
        id: String,
        path: String,
        title: String,
        tags: Set<String>
    ) {
        self.id = id
        self.path = path
        self.title = title
        self.tags = tags
    }
}

public extension TestFlowRegistry {
    static var testSuite: TestSuite {
        TestSuite(Self.self)
    }
}
