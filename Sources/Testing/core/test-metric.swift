public struct TestMetric:
    Sendable,
    Hashable,
    CustomStringConvertible
{
    public enum Unit:
        Sendable,
        Hashable,
        CustomStringConvertible
    {
        case count
        case bytes
        case nanoseconds
        case seconds
        case ratio
        case custom(String)

        public var description: String {
            switch self {
            case .count:
                "count"
            case .bytes:
                "bytes"
            case .nanoseconds:
                "ns"
            case .seconds:
                "s"
            case .ratio:
                "ratio"
            case .custom(let value):
                value
            }
        }
    }

    public let name: String
    public let value: Double
    public let unit: Unit

    public init(
        _ name: String,
        value: Double,
        unit: Unit
    ) {
        self.name = name
        self.value = value
        self.unit = unit
    }

    public var description: String {
        "\(name)=\(value) \(unit.description)"
    }
}
