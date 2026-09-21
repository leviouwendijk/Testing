public struct TestFlowProfile:
    Sendable,
    Hashable,
    Identifiable
{
    public let id: String
    public let skipTags: Set<String>

    public init(
        _ id: String,
        skipTags: Set<String> = []
    ) {
        self.id = id
        self.skipTags = skipTags
    }
}
