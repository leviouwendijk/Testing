public struct TestFlowReportConfiguration: Sendable, Hashable {
    public var color: Bool
    public var verbose: Bool
    public var quiet: Bool
    public var failuresOnly: Bool

    public init(
        color: Bool = true,
        verbose: Bool = false,
        quiet: Bool = false,
        failuresOnly: Bool = false
    ) {
        self.color = color
        self.verbose = verbose
        self.quiet = quiet
        self.failuresOnly = failuresOnly
    }

    public static let `default` = Self()
}

public protocol TestFlowReporting: Sendable {
    func report(
        title: String,
        results: [TestFlowResult],
        configuration: TestFlowReportConfiguration
    )
}
