public enum TestOutcome:
    String,
    Sendable,
    Hashable,
    CaseIterable
{
    case passed
    case failed
    case skipped
    case expected_failure
    case unexpected_pass
    case interrupted

    public var isFailure: Bool {
        switch self {
        case .failed,
             .unexpected_pass,
             .interrupted:
            true

        case .passed,
             .skipped,
             .expected_failure:
            false
        }
    }
}
