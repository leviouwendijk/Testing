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

    public static let `default` = Self()

    public static let all = Self(
        selection: .init()
    )

    public static let fail_fast = Self(
        failFast: true
    )

    public func selecting(
        _ selection: TestSelection
    ) -> Self {
        .init(
            selection: selection,
            failFast: failFast
        )
    }

    public func withFailFast(
        _ enabled: Bool = true
    ) -> Self {
        .init(
            selection: selection,
            failFast: enabled
        )
    }
}
