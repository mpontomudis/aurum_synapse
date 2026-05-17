# GOVERNANCE RUNTIME INTEGRATION MAP V1

**Scope:** `GOVERNANCE_RUNTIME_INTEGRATION_AUDIT_V1` — map how governance may attach to **MAIN EA** (`AurumSynapse.mq5`) as **shadow runtime** without mutating the native execution contract.

**Status:** design + cold-lane primitives (`GovernanceRuntimeShadowContractV1.mqh`, `GovernanceShadowRuntimeLaneV1.mqh`). **No** full umbrella on `OnTick` hot path.

---

## 1. CURRENT MAIN EA FLOW

ASCII diagram (new bar path):

```
OnTick
  → reentrancy guard
  → new-bar gate (skip intrabar except panel)
  → RiskManager.CanTrade()          [native execution gate]
  → time filter / spread filter
  → MarketAnalyzer.Update()
  → StrategyManager.EvaluateAll()
  → SignalManager consensus + QualityFilter score
  → position / consecutive-loss gates
  → ExecuteTrade()                   [native order path]
  → (optional) T1/T2 telemetry row
  → ManageOpenPositions()            [native modify path]
  → UpdatePanel()
```

**Observation:** governance kernel / replay / intelligence stacks are **not** in this path today (`TestGovernanceStateMachineV1.mq5` + offline/join pipelines only).

---

## 2. TARGET SHADOW GOVERNANCE FLOW

Intended **additive** shape (future wiring — not yet binding decisions):

```
OnTick
  → native EA execution (unchanged order)
  → GovRuntimeShadowV1_Capture(...)   [O(1) POD snapshot — optional]
  → GovRuntimeShadowQueueV1_Append    [integer ring — hot path safe]
  → (no replay parse / no export here)

OnTimer / post-session worker (cold)
  → drain ring → replay append / analytics / visualization
  → deferred resilience / evolution / civilization chains (UTF-8 replay only)
```

**Principle:** shadow lane **observes**; **cold path** interprets.

---

## 3. HOT PATH VS COLD PATH

### HOT PATH (must stay lean)

- Order send / modify / close (native `TradeManager`)
- Spread / time gates that block trading
- Signal evaluation + consensus (`StrategyManager`, `SignalManager`)
- Risk execution gate (`RiskManager.CanTrade()` and derived blocks)
- Per-bar telemetry row build **only** if already budgeted (existing T1 path)

### COLD PATH (deferred)

- Multiline replay parser, timeline rebuild, forensic export bundles
- `GovResilLiveV1_Run` / `GovEvoLiveV1_Run` / `GovStrategicLiveV1_Run` / `GovConLiveV1_Run` style UTF-8 pipelines
- Simulation lab, civilization / consciousness stacks
- SHA over large transcripts, policy materialization from disk
- Visualization/dashboard generation

---

## 4. GOVERNANCE INJECTION POINTS (MAIN EA)

| Location | Role | Suggested tag (see `AurumSynapse.mq5` comments) |
|----------|------|---------------------------------------------------|
| After new bar detected | Pre-signal context (bar time, symbol) | `GOV_SHADOW_SAFE_POINT` |
| After `CanTrade()` result | Shadow vs native execution alignment | `GOV_RUNTIME_INJECTION_CANDIDATE` |
| After `MarketAnalyzer` state | Pre-signal regime / quality context | `GOV_SHADOW_SAFE_POINT` |
| Immediately before `ExecuteTrade` | Pre-order shadow snapshot (never block here v1) | `GOV_RUNTIME_INJECTION_CANDIDATE` |
| After native telemetry enqueue | Deferred drain hand-off | `GOV_COLD_PATH_ONLY` |
| After `ManageOpenPositions` | Post-position shadow | `GOV_SHADOW_SAFE_POINT` |
| `OnTimer` | Background persistence / drain | `GOV_COLD_PATH_ONLY` |
| `OnTradeTransaction` (deal out) | Post-trade risk hook alignment | `GOV_SHADOW_SAFE_POINT` |
| Session end / tester stop | Full replay analytics | `GOV_COLD_PATH_ONLY` |

---

## 5. RUNTIME SAFETY RULES

1. **No** multiline replay parsing in `OnTick` hot path.  
2. **No** `FileOpen` / blocking I/O in order execution lane.  
3. **No** SHA / crypto over large blobs per tick.  
4. **No** `Gov*LiveV1_Run` replay chains inside `ExecuteTrade` / spread filter.  
5. **No** recursive orchestration (shadow tick must not re-enter native trade path).  
6. **No** simulation lab / civilization / consciousness stacks on live order path.  
7. **Allowed:** integer ring append, bounded counters, timer-throttled drain, explicit feature flags default **OFF** until orchestration phase.

---

## Related artifacts

- `TelemetryAnalytics/GovernanceRuntimeShadowContractV1.mqh` — snapshot + `GovRuntimeShadowV1_Capture`  
- `TelemetryAnalytics/GovernanceShadowRuntimeLaneV1.mqh` — integer ring queue  
- `TelemetryAnalytics/GOVERNANCE_RUNTIME_PERFORMANCE_RULES_V1.md` — numeric budgets  
