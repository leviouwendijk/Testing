public protocol TestFlowDiagnosticProviding: Error {
    var testFlowDiagnostics: [TestFlowDiagnostic] { get }
}

public enum TestFlowErrorDiagnostics {
    public static func diagnostics(
        for error: Error
    ) -> [TestFlowDiagnostic] {
        if let error = error as? any TestFlowDiagnosticProviding {
            return error.testFlowDiagnostics
        }

        return [
            .message("\(error)")
        ]
    }
}
