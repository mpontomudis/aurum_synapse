# Official telemetry contract — `AS_TELEMETRY_V1` (`TELEMETRY_SCHEMA_VERSION` = **V1**)

This document is the **authoritative column contract** for bar-aligned CSV telemetry. **Writer source of truth:** `Telemetry/TelemetryWriter.mqh` — `TelemetryWriter_CsvHeaderLine()` and `TelemetryWriter_FormatDataLine()`. **Reader / analytics** derive expected width from that header (`TelemetryCsvV1_ExpectedColumns()` in `TelemetryAnalytics/CsvTelemetryReader.mqh`).

**Phase S freeze (2026-05-10):** Do not change column order, delimiter, null policy, or header literals without a new schema id (e.g. `AS_TELEMETRY_V2`) and migration notes in `TelemetrySchema.md` + `Tests/POST_COMPLETION_VALIDATION_ROADMAP.md`.

---

## Global serialization rules

| Topic | Rule |
|-------|------|
| **Schema id** | First data column (index **0**) must equal **`AS_TELEMETRY_V1`** (`TELEMETRY_SCHEMA_ID_ASCII`). |
| **Delimiter** | ASCII comma **`,`** (ushort `44`). |
| **Line endings** | Writer may emit CRLF or LF; Stream A reader treats **physical lines** (byte read until CR/LF). |
| **Int null** | `TELEMETRY_NULL_INT` = **-2147483647**; empty token also treated as null where applicable. |
| **Double null** | `TELEMETRY_NULL_DOUBLE` = **-1e100** (and values ≤ **-1e99**); empty string; NaN → null. |
| **Enums** | Serialized as **int**; map to `Core/Constants.mqh` (and related enums) at interpretation time. |
| **Embedded commas** | Avoid in free text; `bar_time` may contain commas from `TimeToString` — parser **merges** overflow tokens back into column 2 (see `CsvTelemetry_NormalizeColumnCount`). |

---

## File naming & rotation (T2)

| Topic | Rule |
|-------|------|
| **Storage root** | MetaTrader **Common** `Files\` subtree: `AurumSynapse\telemetry\` (`FILE_COMMON`). |
| **Filename pattern** | `AS_TELEMETRY_V1_<SymbolSanitized>_<PeriodMinutes>_<YYYYMMDD>[_<seq>].csv` (`TelemetryRotation_BuildRelativePath`, prefix `TELEMETRY_T2_FILE_PREFIX`). |
| **Analytics glob** | `AurumSynapse\telemetry\AS_TELEMETRY_V1_*.csv` (`ANALYTICS_TELEMETRY_FILE_GLOB`). |
| **Rotation** | New segment on **GMT calendar day** change or when segment size would exceed **50 MB**; continuation uses `_1`, `_2`, … suffix before `.csv`. |

---

## Column index table (0-based, **68** columns)

| IDX | Column | Type | Meaning | Source subsystem | Valid range / notes | Null behavior |
|-----|--------|------|---------|------------------|---------------------|---------------|
| 0 | schema | string | Schema id literal | T2 writer | Must equal `AS_TELEMETRY_V1` | N/A |
| 1 | bar_utc | long (string) | Bar open time as Unix seconds | Market / chart | ≥ 0 typical | As written |
| 2 | bar_time | string | Human-readable bar time (`TimeToString`) | Market | May contain commas (merged on read) | As written |
| 3 | symbol | string | Chart symbol | Market | Non-empty typical | As written |
| 4 | period | int | Period in minutes | Market | > 0 | As written |
| 5 | atr14 | double | ATR(14) | Market | ≥ 0 | Null sentinel |
| 6 | adx | double | ADX | Market | ≥ 0 | Null sentinel; used by **REGIME_PROXY** |
| 7 | bb_width | double | Bollinger bandwidth proxy | Market | ≥ 0 | Null sentinel |
| 8 | ema_slope | double | EMA slope proxy | Market | Any | Null sentinel |
| 9 | spread_points | double | Spread in points | Market | ≥ 0 | Null sentinel |
| 10 | session_code | int | Session bucket code | Market / session | See **Session codes** below | Null sentinel → analytics **SESSION_UNKNOWN** |
| 11 | hour_wit | int | Hour (WIT or broker-aligned per collector) | Market | 0–23 typical | Null sentinel |
| 12 | volatility_ratio | double | Volatility ratio | Market | > 0 typical | Null sentinel; used by **REGIME_PROXY** |
| 13 | efficiency_ratio | double | Efficiency / chop proxy | Market | Any | Null sentinel |
| 14 | false_breakout_cnt | int | False breakout count | Market | ≥ 0 | Null sentinel |
| 15 | liquidity_proxy | double | Liquidity proxy | Market | Any | Null sentinel |
| 16–20 | str0_sig … str0_veto | int / double / int / double / int | Strategy slot **0** (TrendFollowing): signal, strength, active, adaptive weight, veto | Strategy + pipeline | Signal/veto = enums as int | Per-field null rules |
| 21–25 | str1_* | … | Slot **1** Breakout | … | … | … |
| 26–30 | str2_* | … | Slot **2** MeanReversion | … | … | … |
| 31–35 | str3_* | … | Slot **3** SupplyDemand | … | … | … |
| 36–40 | str4_* | … | Slot **4** SmartMoney | … | … | … |
| 41–45 | str5_* | … | Slot **5** PriceAction | … | … | … |
| 46–50 | str6_* | … | Slot **6** GridRecovery | … | … | … |
| 51–55 | str7_* | … | Slot **7** MomentumScalp | … | … | … |
| 56 | quality | double | Pipeline quality score | Pipeline / quality | 0–100 typical in active runs | Null sentinel |
| 57 | consensus | int | Consensus signal code (`ENUM_SIGNAL` as int) | Consensus | Enum range | Null sentinel |
| 58 | consensus_strength | double | Consensus strength | Consensus | ≥ 0 typical | Null sentinel |
| 59 | agreement_pct | double | Strategy agreement % | Consensus | 0–100 typical | Null sentinel |
| 60 | reject_code | int | Reject / filter reason code | Pipeline | Enum / int | As written |
| 61 | risk_halt | int | Risk halt flag (non-zero = halt) | Risk | 0 / 1 typical | Null sentinel |
| 62 | cooldown_flag | int | Cooldown flag | Risk / pipeline | 0 / 1 typical | As written |
| 63 | regime_ph | int | **Placeholder** — not live `ENUM_REGIME` | Trade ctx | T2 placeholder | As written |
| 64 | entry_ctx_ph | int | Entry context placeholder | Trade ctx | Placeholder | As written |
| 65 | hold_sec_ph | int | Hold duration placeholder | Trade ctx | Placeholder | As written |
| 66 | mae_ph | double | MAE placeholder | Trade ctx | Placeholder | Null sentinel |
| 67 | mfe_ph | double | MFE placeholder | Trade ctx | Placeholder | Null sentinel |

Per-slot field order (slot `i` base index **16 + 5×i**): `sig`, `str` (strength), `act` (active 0/1), `wgt` (adaptive weight), `veto` (reject reason or 0).

**Strategy slot index → name** (analytics labels, `StrategyFitness_SlotName`): 0 TrendFollowing, 1 Breakout, 2 MeanReversion, 3 SupplyDemand, 4 SmartMoney, 5 PriceAction, 6 GridRecovery, 7 MomentumScalp.

---

## Session codes (Stream A bucketing)

`SessionAnalytics_Bucket` maps `session_code` to labels:

| Code / condition | Analytics label |
|------------------|-----------------|
| 0 | SESSION_ASIAN |
| 1 | SESSION_LONDON |
| 2 | SESSION_NEWYORK |
| 3 | SESSION_OVERLAP |
| 4–5 | SESSION_OTHER |
| null / invalid | SESSION_UNKNOWN |

*(Exact numeric meaning at capture is defined by the EA’s session classifier; analytics only buckets by this int.)*

---

## REGIME_PROXY (Stream A only — **not** `ENUM_REGIME`)

Derived in `TelemetryAnalytics/RegimeLabels.mqh` from **ADX** and **volatility_ratio** using thresholds in `TelemetryAnalytics/AnalyticsConfig.mqh`:

| Label | Rule (order applied) |
|-------|----------------------|
| HIGH_VOL | `volatility_ratio ≥ 1.12` (and vol not null) |
| LOW_VOL | `volatility_ratio ≤ 0.88` |
| TRENDING | `adx ≥ 28` |
| RANGING | `adx ≤ 18` |
| NEUTRAL | Otherwise |
| UNKNOWN | Reserved |

**Never** fed into execution; descriptive analytics only.

---

## Quality bins (Stream A)

From `QualityAnalytics_ClassifyBin` on `quality`:

| Bin | Range |
|-----|-------|
| QUAL_NULL | null quality |
| QUAL_LT50 | &lt; 50 |
| QUAL_50_60 | 50 ≤ q &lt; 60 |
| QUAL_60_70 | 60 ≤ q &lt; 70 |
| QUAL_GE70 | ≥ 70 |

---

## Consensus interpretation (CSV fields)

| Field | Use |
|-------|-----|
| **consensus** | Dominant directional / action code as int; compare to per-slot `strN_sig` for “signal == consensus” rates in Stream A. |
| **consensus_strength** | Magnitude of consensus. |
| **agreement_pct** | Fractional agreement across participating strategies (0–100 scale as written). |

---

## Version constants (Phase S)

| Constant | Location | Purpose |
|----------|----------|---------|
| `TELEMETRY_SCHEMA_ID_ASCII` | `TelemetryVersion.mqh` | Wire format id |
| `TELEMETRY_SCHEMA_VERSION` | `TelemetryVersion.mqh` | Human tag **V1** |
| `TELEMETRY_SCHEMA_MAJOR` / `MINOR` | `TelemetryVersion.mqh` | Breaking vs additive policy |
| `ANALYTICS_ENGINE_VERSION` | `AnalyticsConfig.mqh` | Stream A code contract |
| `ANALYTICS_STREAM_A_REPORT_VERSION` | `AnalyticsConfig.mqh` | Text report layout / fields |

---

## Related files

- `Telemetry/TelemetrySchema.md` — narrative + header one-liner  
- `Telemetry/TelemetryContracts.mqh` — null sentinels + slot count  
- `Tests/POST_COMPLETION_VALIDATION_ROADMAP.md` — **PHASE S** + TEST C matrix  
- `Baselines/Telemetry_V1/TEST_C_2025/` — frozen regression pointers  
