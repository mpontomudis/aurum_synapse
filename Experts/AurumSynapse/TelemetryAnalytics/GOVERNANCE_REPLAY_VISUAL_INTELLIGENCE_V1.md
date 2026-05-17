# GOVERNANCE_REPLAY_VISUAL_INTELLIGENCE_V1

Deterministic **forensic replay** on top of frozen `GOV_TEL` rows (13-field kernel transcript), `GOV_EVT_V1`, `GOV_ATTRIB_V1`, and `GOV_EXEC_V1` — **schemas are not modified**.

## Layout (`TelemetryAnalytics/GovernanceReplayVisualIntelligenceV1/`)

| Module | Role |
|--------|------|
| `GovernanceReplayDatasetV1.mqh` | `SGovReplayEpochV1`, campaigns, timeline; merge/sort/hash chain. |
| `GovernanceReplayParserV1.mqh` | UTF-8/LF normalize, classify lines, merge by epoch, carry epoch for ATTRIB. |
| `GovernanceReplayIntegrityV1.mqh` | Monotonic epoch order, per-epoch hash length, optional source SHA match. |
| `GovernanceTimelineEngineV1.mqh` | `GOV_TL_V1` deterministic CSV frames. |
| `GovernanceCausalReplayInspectorV1.mqh` | `GOV_CAUS_V1` transition explanations (integer codes). |
| `GovernanceContainmentAnalyticsV1.mqh` | Integer containment metrics over epochs. |
| `GovernancePolicyReplayComparatorV1.mqh` | Forensic deltas between two timelines. |
| `GovernanceReplayExportV1.mqh` | Full export pack (timeline + causal + epoch CSV + JSON-like summary). |
| `GovernanceVisualizationContractsV1.mqh` | Frozen UI panel / axis enums (no rendering). |
| `GovernanceReplayLiveIntegrationV1.mqh` | `FILE_COMMON` log load + parse + integrity. |
| `GovernanceReplayVisualIntelligenceV1.mqh` | Umbrella include. |

## Determinism

Same normalized UTF-8/LF input → same `source_concat_sha256_hex`, same merged epochs, same exports (`GovernanceReplayExportV1_ExportFullPack`).

## Production

Append governance transcripts (existing formats) to a `.log` / `.txt` file under Common; call `GovernanceReplayLiveIntegrationV1_LoadAndParseFromCommonUtf8Lf` then export for offline audit.
