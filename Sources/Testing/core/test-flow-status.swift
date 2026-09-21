public enum TestFlowStatus: String, Sendable, Codable, Hashable, CaseIterable {
    case passed
    case failed
    case skipped
    case expected_failure
    case unexpected_pass
    case interrupted
    case secured
    case vulnerable
    case exploited

    public var isFailure: Bool {
        switch self {
        case .passed,
             .skipped,
             .expected_failure,
             .secured:
            return false

        case .failed,
             .unexpected_pass,
             .interrupted,
             .vulnerable,
             .exploited:
            return true
        }
    }

    public var label: String {
        switch self {
        case .passed:
            return "pass"

        case .failed:
            return "fail"

        case .skipped:
            return "skip"

        case .expected_failure:
            return "xfail"

        case .unexpected_pass:
            return "xpass"

        case .interrupted:
            return "intr"

        case .secured:
            return "secure"

        case .vulnerable:
            return "vuln"

        case .exploited:
            return "exploit"
        }
    }
}
