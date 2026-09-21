public struct TestFlowSelection: Sendable, Hashable {
    public var names: [String]
    public var tags: Set<String>
    public var skipTags: Set<String>
    public var match: [String]

    public init(
        names: [String] = [],
        tags: [String] = [],
        skipTags: [String] = [],
        match: [String] = []
    ) {
        self.names = names
        self.tags = Set(tags)
        self.skipTags = Set(skipTags)
        self.match = match
    }

    public func resolvedNames(
        available: [String]
    ) -> [String] {
        if names.isEmpty || names == ["all"] {
            return available
        }

        return names
    }

    public func accepts(
        name: String,
        displayName: String,
        tags availableTags: Set<String>
    ) -> Bool {
        if !tags.isEmpty,
           availableTags.intersection(tags).isEmpty {
            return false
        }

        if !skipTags.isEmpty,
           !availableTags.intersection(skipTags).isEmpty {
            return false
        }

        if !match.isEmpty,
           !matches(
               name: name,
               displayName: displayName,
               tags: availableTags
           ) {
            return false
        }

        return true
    }
}

private extension TestFlowSelection {
    func matches(
        name: String,
        displayName: String,
        tags: Set<String>
    ) -> Bool {
        let haystack = ([name, displayName] + tags.sorted())
            .map {
                $0.lowercased()
            }

        return match.contains { query in
            let query = query.lowercased()

            return haystack.contains { value in
                value.contains(
                    query
                )
            }
        }
    }
}
