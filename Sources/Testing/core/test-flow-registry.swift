public protocol TestFlowRegistry: Sendable {
    static var title: String { get }
    static var flows: [TestFlow] { get }
    static var profiles: [TestFlowProfile] { get }
    static var defaultProfile: String? { get }
}

public extension TestFlowRegistry {
    static var profiles: [TestFlowProfile] {
        []
    }

    static var defaultProfile: String? {
        nil
    }
}
