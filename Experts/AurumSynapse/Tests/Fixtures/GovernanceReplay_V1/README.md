# GovernanceReplay_V1 — Fixture Pack (PHASE 8A)

**Purpose:** Deterministic replay inputs and expected governance telemetry for `GOVERNANCE_STATE_MACHINE_V1` in **`GOVERNANCE_SHADOW_MODE` only**.

**Normative spec:** `TelemetryAnalytics/PHASE_8A_GOVERNANCE_STATE_MACHINE_IMPLEMENTATION_SPEC.md`  
**Policy source (frozen):** `TelemetryAnalytics/PHASE_8_GOVERNANCE_POLICY_TABLES_V1.md`

## Layout

Each scenario is a directory:

- `manifest.json` — `policy_id`, `policy_semver`, `policy_checksum_sha256`, optional `expected_transcript_sha256`  
- `inputs.csv` — one row per `gov_epoch`; columns per 8A spec §8.2  
- `expected.telemetry` — optional line-exact golden (preferred for CI); if omitted, manifest hash must be set after first blessed run

## Scenario list (required)

| Directory | Intent |
|-----------|--------|
| `S01_stable_market/` | Baseline: remain `GS_NORMAL`, low evidence |
| `S02_volatile_market/` | Regime volatility + dwell_regime |
| `S03_toxicity_escalation/` | Toxicity latch + `E_tox` max path |
| `S04_survivability_collapse/` | Survivability latch + `E_surv` max path |
| `S05_failed_recovery_loop/` | Causal failed recovery + CONF / RF penalty |
| `S06_panic_collapse/` | Structural / panic causal + quarantine Q2 |
| `S07_quarantine_escalation/` | Severity ramp with `dwell_q_on` / `dwell_q_off` |
| `S08_recovery_stabilization/` | SURVIVAL/LOCKDOWN → RECOVERY → DEFENSIVE (no skip to NORMAL) |
| `S09_oscillating_noise/` | Square-wave inputs; assert transition cap |

## Determinism rules

1. **No floats in CSV** — all scores are integers in documented ranges.  
2. **Canonical row order** — ascending `epoch`.  
3. **Policy bytes** — checksum in manifest must match loaded bundle.  
4. **Telemetry** — compare full line strings (pipe-delimited, §6 of 8A spec).

## Harness

Implemented by `Tests/TestGovernanceStateMachineV1.mq5` (to be added with first code drop). It shall:

- Load manifest  
- Load policy bundle from `MQL5/Files/...` or embedded test vector  
- Step epochs, append telemetry to temp file  
- Diff against `expected.telemetry` or verify transcript hash  

## Status

**Scaffold:** directory and contract only; per-scenario `manifest.json` / `inputs.csv` / `expected.telemetry` are populated when the first reference bundle `POLICY_CHECKSUM_REF` is published (policy doc §1.5 golden fixture lock).
