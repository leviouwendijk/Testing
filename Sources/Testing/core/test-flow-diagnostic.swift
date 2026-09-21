public enum TestFlowDiagnostic: Sendable, Hashable, ExpressibleByStringInterpolation, CustomStringConvertible {
    case message(String)
    case field(String, String)
    case section(String, [String])
    case event(String)
    case diff(String, String)
    case table(String, TestFlowTable)
    case timeline(String, [TestFlowTimelineEntry])
    case metric(TestFlowMetric)
    case command(TestFlowCommandDiagnostic)
    case security(TestFlowSecurityFinding)

    public init(
        stringLiteral value: String
    ) {
        self = .message(value)
    }

    public init(
        stringInterpolation: DefaultStringInterpolation
    ) {
        self = .message(
            String(
                stringInterpolation: stringInterpolation
            )
        )
    }

    public var description: String {
        switch self {
        case .message(let value):
            return value

        case .field(let name, let value):
            return "\(name)=\(value)"

        case .section(let title, let lines):
            guard !lines.isEmpty else {
                return title
            }

            return ([title] + lines.map { "    \($0)" }).joined(
                separator: "\n"
            )

        case .event(let value):
            return value

        case .diff(let title, let value):
            guard !title.isEmpty else {
                return value
            }

            guard !value.isEmpty else {
                return title
            }

            return [
                title,
                value
            ].joined(
                separator: "\n"
            )

        case .table(let title, let table):
            return table.description(
                title: title
            )

        case .timeline(let title, let entries):
            return TestFlowTimelineEntry.description(
                title: title,
                entries: entries
            )

        case .metric(let metric):
            return metric.description

        case .command(let command):
            return command.description

        case .security(let finding):
            return finding.description
        }
    }
}

public struct TestFlowTable: Sendable, Hashable {
    public var columns: [String]
    public var rows: [[String]]

    public init(
        columns: [String],
        rows: [[String]]
    ) {
        self.columns = columns
        self.rows = rows
    }

    public func description(
        title: String
    ) -> String {
        var lines: [String] = [
            title
        ]

        guard !columns.isEmpty else {
            lines.append(
                contentsOf: rows.map {
                    "    \($0.joined(separator: " | "))"
                }
            )

            return lines.joined(
                separator: "\n"
            )
        }

        lines.append(
            "    \(columns.joined(separator: " | "))"
        )

        for row in rows {
            lines.append(
                "    \(row.joined(separator: " | "))"
            )
        }

        return lines.joined(
            separator: "\n"
        )
    }
}

public struct TestFlowTimelineEntry: Sendable, Hashable {
    public var time: String
    public var name: String
    public var detail: String?

    public init(
        time: String,
        name: String,
        detail: String? = nil
    ) {
        self.time = time
        self.name = name
        self.detail = detail
    }

    public static func description(
        title: String,
        entries: [Self]
    ) -> String {
        var lines: [String] = [
            title
        ]

        for entry in entries {
            if let detail = entry.detail {
                lines.append(
                    "    \(entry.time) \(entry.name) \(detail)"
                )
            } else {
                lines.append(
                    "    \(entry.time) \(entry.name)"
                )
            }
        }

        return lines.joined(
            separator: "\n"
        )
    }
}

public struct TestFlowMetric: Sendable, Hashable, CustomStringConvertible {
    public var name: String
    public var value: String
    public var unit: String?

    public init(
        name: String,
        value: String,
        unit: String? = nil
    ) {
        self.name = name
        self.value = value
        self.unit = unit
    }

    public var description: String {
        if let unit {
            return "\(name)=\(value) \(unit)"
        }

        return "\(name)=\(value)"
    }
}

public struct TestFlowCommandDiagnostic: Sendable, Hashable, CustomStringConvertible {
    public var command: String
    public var exitCode: Int32?
    public var stdout: String
    public var stderr: String

    public init(
        command: String,
        exitCode: Int32? = nil,
        stdout: String = "",
        stderr: String = ""
    ) {
        self.command = command
        self.exitCode = exitCode
        self.stdout = stdout
        self.stderr = stderr
    }

    public var description: String {
        var lines: [String] = [
            "command=\(command)"
        ]

        if let exitCode {
            lines.append(
                "exit_code=\(exitCode)"
            )
        }

        if !stdout.isEmpty {
            lines.append(
                "stdout:"
            )
            lines.append(
                contentsOf: stdout.split(
                    separator: "\n",
                    omittingEmptySubsequences: false
                ).map {
                    "    \($0)"
                }
            )
        }

        if !stderr.isEmpty {
            lines.append(
                "stderr:"
            )
            lines.append(
                contentsOf: stderr.split(
                    separator: "\n",
                    omittingEmptySubsequences: false
                ).map {
                    "    \($0)"
                }
            )
        }

        return lines.joined(
            separator: "\n"
        )
    }
}

public extension TestFlowDiagnostic {
    static func value<T>(
        _ name: String,
        _ value: T
    ) -> Self {
        .field(
            name,
            String(describing: value)
        )
    }
}

public extension TestFlowSecurityFinding {
    var description: String {
        var lines: [String] = [
            "\(kind.rawValue) \(severity.rawValue)"
        ]

        if let id {
            lines.append(
                "    id=\(id.rawValue)"
            )
        }

        lines.append(
            "    result=\(resultLabel)"
        )
        lines.append(
            "    title=\(title)"
        )

        if let vector {
            lines.append(
                "    vector=\(vector)"
            )
        }

        if let impact {
            lines.append(
                "    impact=\(impact)"
            )
        }

        if let evidence {
            lines.append(
                "    evidence=\(evidence)"
            )
        }

        if !references.isEmpty {
            lines.append(
                "    references:"
            )

            lines.append(
                contentsOf: references.map {
                    "        \($0.kind.rawValue)=\($0.value)"
                }
            )
        }

        return lines.joined(
            separator: "\n"
        )
    }
}
