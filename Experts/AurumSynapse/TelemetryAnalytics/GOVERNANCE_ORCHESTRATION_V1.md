# GOVERNANCE_ORCHESTRATION_V1 (LIVE)

Deterministic bridge from **governance evidence + kernel shadow tick** to **`SGovernanceExecutionContractV1`** and append-only **`GOV_EXEC_V1`** telemetry. No broker calls and no order placement inside this layer.

## Entry points

| API | Role |
|-----|------|
| `GovernanceExecutionOrchestratorV1_RunPipelineFromDealsUtf8` | Single-epoch pipeline: shadow tick (deals UTF-8 LF) → quarantine/throttle/survivability/gate → contract + `GOV_EXEC_V1` line. |
| `GovEvidenceIntegrationV1_ShadowTickFromDealsUtf8(..., SGovShadowTickAuxOutV1 &aux)` | Evidence + kernel tick; fills `aux` with causal code, market regime, tox/surv states, runtime evidence, evidence fp8. |
| `ProductionGovernanceOrchestrationJoinHookV1_OnJoinedBatch` | Production join: after deals blob load, runs one orchestration and appends UTF-8 LF line to `{outputJoinedRelPath}.gov_exec_v1.log` under `FILE_COMMON`. |

## Live EA integration

1. Load verified `SCGovPolicySnapshotV1` (same loader as kernel).
2. Hold one `SGovernanceShadowContextV1` and one `SGovernanceCampaignMemoryV1` across ticks (replay memory).
3. Each epoch with immutable deals snapshot: call `GovernanceExecutionOrchestratorV1_RunPipelineFromDealsUtf8`.
4. Read **`SGovernanceExecutionContractV1`** only after success; on failure treat as **fail-closed** (no entries, no recovery).
5. Append `GOV_EXEC_V1` line to your append-only store using `GovernanceExecutionTelemetryV1_AppendUtf8LfCommon` or equivalent (UTF-8, LF, deterministic field order).

## Contracts

- **Execution contract:** `TelemetryAnalytics/GovernanceOrchestrationV1/GovernanceExecutionContractV1.mqh`
- **Execution telemetry:** `GOV_EXEC_V1` schema and field count in `GovernanceExecutionTelemetryV1.mqh` (`GOV_EXEC_V1_EXPECTED_PIPE_FIELDS`).
- **Existing schemas unchanged:** `GOV_EVT_V1` / `GOV_ATTRIB_V1` are not modified; orchestration adds a parallel stream only.

## Replay determinism

Same policy snapshot, same deals UTF-8 LF, same initial `SGovernanceShadowContextV1` / `SGovernanceCampaignMemoryV1` / regime dwell inputs → same shadow telemetry, same fused evidence, same contract and same `GOV_EXEC_V1` line (validated in `TestGovernanceStateMachineV1.mq5`).

## Extensibility

Add new deterministic signals by extending `GovernanceQuarantineEngineV1_Classify`, `GovernanceThrottleEngineV1_ComputeIntervalMs`, or `GovernanceSurvivabilityProtectorV1_Evaluate` — keep integer-only paths and avoid wall-clock or `Sleep()` in this layer.
