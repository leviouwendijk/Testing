public extension Expect {
    static func hasPrefix(
        _ actual: String,
        _ expectedPrefix: String,
        _ label: String
    ) throws {
        guard actual.hasPrefix(expectedPrefix) else {
            throw TestFlowAssertionFailure(
                label: label,
                message: "string did not have expected prefix",
                actual: actual,
                expected: "prefix \(expectedPrefix)"
            )
        }
    }

    static func hasPrefix(
        _ actual: String?,
        _ expectedPrefix: String,
        _ label: String
    ) throws -> String {
        let actual = try notNil(
            actual,
            label
        )

        try hasPrefix(
            actual,
            expectedPrefix,
            label
        )

        return actual
    }
}
