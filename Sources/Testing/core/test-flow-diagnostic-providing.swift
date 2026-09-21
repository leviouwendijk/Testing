public protocol TestDiagnosticProviding: Error {
    var testDiagnostics: [TestDiagnostic] { get }
}

public enum TestErrorDiagnostics {
    public static func diagnostics(
        for error: Error
    ) -> [TestDiagnostic] {
        if let error = error as? any TestDiagnosticProviding {
            return error.testDiagnostics
        }

        return [
            .message("\(error)")
        ]
    }
}

@available(*, deprecated, renamed: "TestDiagnosticProviding")
public typealias TestFlowDiagnosticProviding = TestDiagnosticProviding

@available(*, deprecated, renamed: "TestErrorDiagnostics")
public typealias TestFlowErrorDiagnostics = TestErrorDiagnostics

public extension TestDiagnosticProviding {
    @available(*, deprecated, renamed: "testDiagnostics")
    var testFlowDiagnostics: [TestDiagnostic] {
        testDiagnostics
    }
}
