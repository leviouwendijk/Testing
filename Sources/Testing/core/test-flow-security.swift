public struct TestFlowSecurityID:
    RawRepresentable,
    Sendable,
    Codable,
    Hashable,
    ExpressibleByStringLiteral,
    CustomStringConvertible
{
    public var rawValue: String

    public init(
        _ rawValue: String
    ) {
        self.rawValue = rawValue
    }

    public init(
        rawValue: String
    ) {
        self.rawValue = rawValue
    }

    public init(
        stringLiteral value: String
    ) {
        self.rawValue = value
    }

    public var description: String {
        rawValue
    }
}

public enum TestFlowSecurityFindingKind: String, Sendable, Codable, Hashable, CaseIterable {
    case vulnerability
    case exploit
}

public enum TestFlowSecuritySeverity: String, Sendable, Codable, Hashable, CaseIterable {
    case info
    case low
    case medium
    case high
    case critical
}

public enum TestFlowSecurityReferenceKind: String, Sendable, Codable, Hashable, CaseIterable {
    case cwe
    case cve
    case advisory
    case reference
}

public struct TestFlowSecurityReference: Sendable, Codable, Hashable, ExpressibleByStringLiteral, CustomStringConvertible {
    public var kind: TestFlowSecurityReferenceKind
    public var value: String

    public init(
        kind: TestFlowSecurityReferenceKind,
        value: String
    ) {
        self.kind = kind
        self.value = value
    }

    public init(
        stringLiteral value: String
    ) {
        self.init(
            kind: .reference,
            value: value
        )
    }

    public static func cwe(
        _ value: String
    ) -> Self {
        .init(
            kind: .cwe,
            value: value
        )
    }

    public static func cve(
        _ value: String
    ) -> Self {
        .init(
            kind: .cve,
            value: value
        )
    }

    public static func advisory(
        _ value: String
    ) -> Self {
        .init(
            kind: .advisory,
            value: value
        )
    }

    public static func reference(
        _ value: String
    ) -> Self {
        .init(
            kind: .reference,
            value: value
        )
    }

    public var description: String {
        "\(kind.rawValue)=\(value)"
    }
}

public struct TestFlowSecurityFinding: Sendable, Codable, Hashable {
    public var id: TestFlowSecurityID?
    public var kind: TestFlowSecurityFindingKind
    public var severity: TestFlowSecuritySeverity
    public var title: String
    public var vector: String?
    public var impact: String?
    public var evidence: String?
    public var references: [TestFlowSecurityReference]
    public var reproduced: Bool

    public init(
        id: TestFlowSecurityID? = nil,
        kind: TestFlowSecurityFindingKind,
        severity: TestFlowSecuritySeverity,
        title: String,
        vector: String? = nil,
        impact: String? = nil,
        evidence: String? = nil,
        references: [TestFlowSecurityReference] = [],
        reproduced: Bool
    ) {
        self.id = id
        self.kind = kind
        self.severity = severity
        self.title = title
        self.vector = vector
        self.impact = impact
        self.evidence = evidence
        self.references = references
        self.reproduced = reproduced
    }

    public var status: TestFlowStatus {
        guard reproduced else {
            return .secured
        }

        switch kind {
        case .vulnerability:
            return .vulnerable

        case .exploit:
            return .exploited
        }
    }

    public var resultLabel: String {
        reproduced ? "reproduced" : "blocked"
    }

    public var identifierLabel: String {
        id?.rawValue ?? title
    }
}

public struct TestFlowSecuritySignal: Error, Sendable, TestDiagnosticProviding {
    public var finding: TestFlowSecurityFinding

    public init(
        finding: TestFlowSecurityFinding
    ) {
        self.finding = finding
    }

    public var status: TestFlowStatus {
        finding.status
    }

    public var testDiagnostics: [TestDiagnostic] {
        [
            .security(finding)
        ]
    }
}
