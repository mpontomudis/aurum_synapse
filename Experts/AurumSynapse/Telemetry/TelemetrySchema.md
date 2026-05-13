# Telemetry schema — `AS_TELEMETRY_V1` (T0 contract)

## Versioning philosophy

**Freeze (2026-05-12):** **`AS_TELEMETRY_V1`** is **STABLE / VERSION-LOCKED** for T1/T2 + Phase 3A Stream A. No breaking header or column-order changes without **`AS_TELEMETRY_V2`** (or later) and migration notes in this file + `Tests/POST_COMPLETION_VALIDATION_ROADMAP.md` (**`### PHASE 3A — COMPLETION FREEZE (official) — 2026-05-12`**).

**Full column contract (index / types / nulls / analytics semantics):** **`Telemetry/TELEMETRY_CONTRACT.md`** (Phase S — 2026-05-10).

- **`AS_TELEMETRY_V1`**: first frozen layout for bar-aligned research exports.
- **Minor** additive change: append **new columns at end** only; parsers ignore unknown tail.
- **Major** breaking change: new schema id **`AS_TELEMETRY_V2`**; never silently rename mid-column semantics.

## Bar row — logical column order (T1+ CSV target)

1. `schema` — literal `AS_TELEMETRY_V1`
2. `bar_utc` — `long` Unix seconds (recommended) *or* documented string format (pick one at T1 lock)
3. `bar_time` — `datetime` as printed audit field (optional duplicate)
4. `symbol`, `period` — string + int minutes
5. **Market A:** `atr14`, `adx`, `bb_width`, `ema_slope`, `spread_points`, `session_code`, `hour_wit`, `volatility_ratio`, `efficiency_ratio`, `false_breakout_cnt`, `liquidity_proxy`
6. **Strategy B (×8):** for `i` in `0..7`: `sig_i`, `str_i`, `act_i`, `wgt_i`, `veto_i`  
   - `sig_i` = `ENUM_SIGNAL` as **int**  
   - `veto_i` = `ENUM_SIGNAL_REJECT_REASON` or reserved `0` when N/A
7. **Pipeline C:** `quality`, `consensus`, `consensus_strength`, `agreement_pct`, `reject_code`, `risk_halt`, `cooldown_flag`
8. **Trade D (placeholders):** `regime_ph`, `entry_ctx_ph`, `hold_sec_ph`, `mae_ph`, `mfe_ph`

## Null / default handling

- Numeric “unset” at T0 init: see `TELEMETRY_NULL_DOUBLE` / `TELEMETRY_NULL_INT` in `TelemetryContracts.mqh`.
- T1+ writers may replace with real values; must not use null sentinels for **real** zero if zero is valid (document per field).

## Enum serialization

- Always **int** column; map to `Core/Constants.mqh` definitions.

## CSV compatibility

- Prefer **numeric** columns; avoid free-text with commas.
- UTF-8 without BOM if tool chain allows; else ASCII-only numerics.

## Canonical CSV header (single line)

```
schema,bar_utc,bar_time,symbol,period,atr14,adx,bb_width,ema_slope,spread_points,session_code,hour_wit,volatility_ratio,efficiency_ratio,false_breakout_cnt,liquidity_proxy,str0_sig,str0_str,str0_act,str0_wgt,str0_veto,str1_sig,str1_str,str1_act,str1_wgt,str1_veto,str2_sig,str2_str,str2_act,str2_wgt,str2_veto,str3_sig,str3_str,str3_act,str3_wgt,str3_veto,str4_sig,str4_str,str4_act,str4_wgt,str4_veto,str5_sig,str5_str,str5_act,str5_wgt,str5_veto,str6_sig,str6_str,str6_act,str6_wgt,str6_veto,str7_sig,str7_str,str7_act,str7_wgt,str7_veto,quality,consensus,consensus_strength,agreement_pct,reject_code,risk_halt,cooldown_flag,regime_ph,entry_ctx_ph,hold_sec_ph,mae_ph,mfe_ph
```

## T2 shadow CSV (storage contract)

- **When:** `#define AURUM_TELEMETRY_T2` with `#define AURUM_TELEMETRY_T1` in `AurumSynapse.mq5` (T2 includes enforce T1 via `TelemetryConfig.mqh`).
- **Where:** MetaTrader **Common** data folder, relative path `AurumSynapse\telemetry\` (`FILE_COMMON` flag on all `File*` calls).
- **Row bytes:** First line is exactly the canonical header above (`TelemetryWriter_CsvHeaderLine()`); each following line is one bar row (`TelemetryWriter_FormatDataLine()`), newline-terminated.
- **Rotation:** Segment rolls on **GMT calendar day** change or when file size would exceed **50 MB**; continuation files use suffix `_1`, `_2`, … after `YYYYMMDD`.
