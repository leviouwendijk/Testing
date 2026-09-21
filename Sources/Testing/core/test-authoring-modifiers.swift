public extension Test {
    func named(
        _ title: String
    ) -> Self {
        .init(
            id,
            title: title,
            tags: tags,
            skip: skipReason,
            expectedFailure: expectedFailure,
            sourceLocation: sourceLocation,
            operation: operation
        )
    }

    func tagged(
        _ tags: String...
    ) -> Self {
        tagged(
            Set(tags)
        )
    }

    func tagged(
        _ additionalTags: Set<String>
    ) -> Self {
        .init(
            id,
            title: title,
            tags: tags.union(additionalTags),
            skip: skipReason,
            expectedFailure: expectedFailure,
            sourceLocation: sourceLocation,
            operation: operation
        )
    }

    func skipped(
        _ reason: String
    ) -> Self {
        .init(
            id,
            title: title,
            tags: tags,
            skip: reason,
            expectedFailure: expectedFailure,
            sourceLocation: sourceLocation,
            operation: operation
        )
    }

    func disabled(
        when condition: Bool,
        reason: String
    ) -> Self {
        condition
            ? skipped(reason)
            : self
    }

    func expectedFailure(
        _ reason: String
    ) -> Self {
        .init(
            id,
            title: title,
            tags: tags,
            skip: skipReason,
            expectedFailure: reason,
            sourceLocation: sourceLocation,
            operation: operation
        )
    }
}
