public typealias TestSelection = TestFlowSelection

public extension TestFlowSelection {
    func accepts(
        path: String,
        name: String,
        displayName: String,
        tags availableTags: Set<String>
    ) -> Bool {
        if !names.isEmpty,
           names != ["all"],
           !names.contains(name),
           !names.contains(path) {
            return false
        }

        return accepts(
            name: path,
            displayName: displayName,
            tags: availableTags
        )
    }
}
