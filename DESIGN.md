# Testing

`Testing` is the standalone semantic testing engine.

## Boundary

The package intentionally has zero external package dependencies and declares no platform floor.

Foundation remains temporarily permitted for portable value and timing utilities. Platform-specific execution behavior, terminal presentation, filesystem integration, snapshots, process integration, and rich diff rendering belong above this package.

## Core responsibilities

`Testing` owns:

- test and suite definitions;
- hierarchical suites and inherited tags;
- selection and execution;
- structured outcomes, issues, diagnostics, and source locations;
- fatal requirements and non-fatal expectations;
- fixtures and runtime-neutral cleanup policies;
- semantic execution events;
- parameterized tests;
- deterministic seeded property tests;
- benchmark sampling and statistics;
- probes and lightweight fixture conveniences;
- plain text reporting without terminal dependencies.

`TestFlows` owns richer integrations such as Terminal, Difference, snapshots, filesystem persistence, CLI behavior, and Swift-task-aware cleanup.

## Compatibility

The existing `TestFlow`, `TestFlowRegistry`, `TestFlowResult`, and related APIs remain available while consumers migrate. New code should prefer `Test`, `TestSuite`, `TestRunner`, `TestContext`, and `TestOutcome` for generic testing semantics.
