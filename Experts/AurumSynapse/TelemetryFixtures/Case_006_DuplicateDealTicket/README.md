# Case_006_DuplicateDealTicket

**Policy:** `PHASE_3B_GOLDEN_FIXTURE_VALIDATION.md` §A6 — deterministic duplicate `d_ticket` collapse before join.

## Intent

`deals.csv` contains **two** data rows with the **same** `d_ticket` (export merge, broker anomaly, duplicated import). The harness must pick **exactly one** canonical deal row, join **once**, emit **`j_join_status=OK`**, and never pick randomly between duplicates.

## Canonical row (frozen order)

Among all rows sharing the same `d_ticket`:

1. **Minimum** `d_time_utc` wins.  
2. If tied: **lexical** `StringCompare` on the full raw CSV data line (UTF-8 bytes as MQL5 string).  
3. If still tied: **earlier physical line** in the file (smaller line index).

This fixture uses different `d_time_utc` values so rule (1) alone selects the canonical row.

## Fixture

| Row | `d_ticket` | `d_time_utc` |
|-----|------------|--------------|
| A (canonical) | `900006` | `1735689725` |
| B (ignored)   | `900006` | `1735689780` |

Telemetry: single bar `1735689600` (same shape as Case_001).

**Expected:** one joined slim row for ticket `900006` at **`1735689725`**, latency **125**, `CASE006-PROTO-1`.

## Why PASS (not FAIL)

Duplicate ticket here is modeled as **recoverable input corruption**: the suite documents deterministic **canonical selection** and still produces a valid **`OK`** join for analytics validation. A separate production policy could **FAIL** the whole batch on duplicate tickets; this golden case freezes **validator-side** resolution for replay-stable harnesses.

## Deploy

Copy under `Terminal\Common\Files\AurumSynapse\TelemetryFixtures\` per parent `README.md`.
