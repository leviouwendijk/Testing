public enum TestFlowActionKind: String, Sendable, Hashable, CaseIterable {
    case step
    case check
    case diagnostic
    case vulnerability
    case exploit

    public var secureSuccessStatus: TestFlowStatus {
        switch self {
        case .vulnerability,
             .exploit:
            return .secured

        case .step,
             .check,
             .diagnostic:
            return .passed
        }
    }
}
