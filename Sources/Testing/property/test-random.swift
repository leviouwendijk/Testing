public struct TestRandom: Sendable {
    private var state: UInt64

    public init(
        seed: UInt64
    ) {
        self.state = seed
    }

    public mutating func nextUInt64() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15

        var value = state
        value = (
            value ^ (value >> 30)
        ) &* 0xBF58476D1CE4E5B9
        value = (
            value ^ (value >> 27)
        ) &* 0x94D049BB133111EB

        return value ^ (value >> 31)
    }

    public mutating func bool() -> Bool {
        nextUInt64() & 1 == 1
    }

    public mutating func int(
        in range: ClosedRange<Int>
    ) -> Int {
        precondition(
            range.lowerBound <= range.upperBound
        )

        let width = UInt64(
            range.upperBound
                - range.lowerBound
                + 1
        )

        return range.lowerBound
            + Int(
                nextUInt64() % width
            )
    }

    public mutating func doubleUnitInterval() -> Double {
        let value = nextUInt64() >> 11

        return Double(value)
            / Double(UInt64(1) << 53)
    }

    public mutating func element<Value>(
        of values: [Value]
    ) -> Value? {
        guard !values.isEmpty else {
            return nil
        }

        return values[
            int(
                in: 0...(values.count - 1)
            )
        ]
    }
}
