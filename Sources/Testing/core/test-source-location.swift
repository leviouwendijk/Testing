public struct TestSourceLocation:
    Sendable,
    Hashable,
    CustomStringConvertible
{
    public let fileID: String
    public let filePath: String
    public let line: UInt
    public let column: UInt

    public init(
        fileID: String = #fileID,
        filePath: String = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) {
        self.fileID = fileID
        self.filePath = filePath
        self.line = line
        self.column = column
    }

    public var description: String {
        "\(fileID):\(line):\(column)"
    }
}
