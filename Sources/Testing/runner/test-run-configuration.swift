public struct TestRunConfiguration:
    Sendable,
    Hashable
{
    public var selection: TestSelection
    public var failFast: Bool

    public init(
        selection: TestSelection = .init(),
        failFast: Bool = false
    ) {
        self.selection = selection
        self.failFast = failFast
    }
}
