public protocol TestFlowCase: RawRepresentable, CaseIterable, Sendable
where RawValue == String, AllCases: Collection, AllCases.Element == Self {
    var displayName: String { get }
    var tags: Set<String> { get }
    var skipReason: String? { get }
    var expectedFailure: String? { get }

    func run() async throws -> TestFlowResult
}

public extension TestFlowCase {
    var displayName: String {
        rawValue
    }

    var tags: Set<String> {
        []
    }

    var skipReason: String? {
        nil
    }

    var expectedFailure: String? {
        nil
    }
}
