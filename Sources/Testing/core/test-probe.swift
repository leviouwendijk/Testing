public actor TestProbe<Value: Sendable> {
    private var values: [Value]

    public init() {
        self.values = []
    }

    public func record(
        _ value: Value
    ) {
        values.append(value)
    }

    public func snapshot() -> [Value] {
        values
    }

    public func last() -> Value? {
        values.last
    }

    public func count() -> Int {
        values.count
    }

    public func reset() {
        values.removeAll(
            keepingCapacity: true
        )
    }
}
