# GOVERNANCE RUNTIME PERFORMANCE RULES V1

Hard budgets for **MAIN EA** integration and any **shadow runtime** lane that shares the tick thread.

---

## MAX ALLOWED (strict — hot path)

| Rule | Rationale |
|------|-----------|
| **No** dynamic replay rebuild per tick | Parser + timeline = unbounded CPU / stack risk |
| **No** SHA / checksum recompute per tick on large buffers | Crypto dominates; belongs in cold worker |
| **No** export generation (`ExportFullPack`, forensic bundles) in execution path | Filesystem latency + journal spam |
| **No** simulation lab / stress engines in `OnTick` | Deterministic harness only |
| **No** resilience / evolution / civilization / consciousness UTF-8 chains during order placement | Those APIs assume offline replay blobs |
| **No** nested `GovernanceExecutionOrchestratorV1` from inside `ExecuteTrade` | Prevents recursion + double accounting |

---

## ALLOWED (shadow lane — bounded)

| Mechanism | Constraint |
|-----------|------------|
| **Lightweight snapshots** | `SGovRuntimeShadowSnapshotV1` — fixed struct, no heap growth |
| **Integer scoring** | 0–100 clamps, basis points, bit flags |
| **Ring buffer append** | `GovRuntimeShadowQueueV1_Append` — O(1), fixed capacity |
| **Deferred processing** | Drain in `OnTimer`, tester end, or dedicated worker |
| **Timer throttling** | e.g. coalesce to ≥250–1000 ms unless proven safe lower |

---

## Measurement discipline

- Before promoting any shadow hook to default **ON**, capture: `GetTickCount()` delta over N bars in tester, max stack depth, and `FILE_COMMON` write rate.  
- Regression: **native** EA with shadow **OFF** must remain bit-identical to pre-shadow baseline for trade counts (within existing MANIFEST tolerance).

---

## Version

**GOVERNANCE_RUNTIME_PERFORMANCE_RULES_V1** — companion to `GOVERNANCE_RUNTIME_INTEGRATION_MAP_V1.md`.
