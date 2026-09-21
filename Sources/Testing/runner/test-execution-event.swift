public enum TestExecutionEvent: Sendable {
    case run_started(
        title: String,
        totalTests: Int
    )
    case suite_started(TestSuiteDescriptor)
    case test_started(TestDescriptor)
    case issue_recorded(
        TestIssue,
        test: TestDescriptor
    )
    case diagnostic_recorded(
        TestFlowDiagnostic,
        test: TestDescriptor
    )
    case test_finished(TestResult)
    case suite_finished(
        TestSuiteDescriptor,
        resultCount: Int
    )
    case run_finished(TestRunResult)
}
