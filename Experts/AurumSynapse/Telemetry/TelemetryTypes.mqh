//+------------------------------------------------------------------+
//|                                                TelemetryTypes.mqh |
//|                    Aurum Synapse — T0 Telemetry Schema Foundation |
//| POD snapshots only — no I/O, no indicator math, no engine writes.|
//+------------------------------------------------------------------+
#ifndef __AURUM_TELEMETRY_TYPES_MQH__
#define __AURUM_TELEMETRY_TYPES_MQH__

#include "../Core/Constants.mqh"
#include "TelemetryVersion.mqh"
#include "TelemetryEnums.mqh"
#include "TelemetryContracts.mqh"

//+------------------------------------------------------------------+
//| A — Market snapshot (T0 placeholders; filled by collectors T1+)  |
//+------------------------------------------------------------------+
struct TelemetryMarketSnapshot {
    datetime bar_time;
    string   symbol;
    int      period_minutes;
    double   atr14;
    double   adx;
    double   bb_width;
    double   ema_slope;
    double   spread_points;
    int      session_code;
    int      hour_wit;
    double   volatility_ratio;
    double   efficiency_ratio;
    int      false_breakout_count;
    double   liquidity_proxy;
};

//+------------------------------------------------------------------+
//| B — Per-strategy snapshot (8 slots; indices match Constants)      |
//+------------------------------------------------------------------+
struct TelemetryStrategySnapshot {
    int      signal_code;
    double   strength;
    int      is_active;
    double   adaptive_weight;
    int      veto_reason_code;
};

//+------------------------------------------------------------------+
//| C — Pipeline / gate snapshot                                      |
//+------------------------------------------------------------------+
struct TelemetryPipelineSnapshot {
    double   quality_score;
    int      consensus_code;
    double   consensus_strength;
    double   agreement_pct;
    int      reject_reason_code;
    int      risk_halt_flag;
    int      cooldown_flag;
};

//+------------------------------------------------------------------+
//| D — Trade / position context (T0 placeholders only)             |
//+------------------------------------------------------------------+
struct TelemetryTradeSnapshot {
    int      regime_placeholder;
    int      entry_context_placeholder;
    int      hold_duration_sec_placeholder;
    double   mae_placeholder;
    double   mfe_placeholder;
};

//+------------------------------------------------------------------+
//| Full bar-row bundle (A + B×8 + C + D)                             |
//+------------------------------------------------------------------+
struct TelemetryBarRow {
    string   schema_id;
    TelemetryMarketSnapshot      market;
    TelemetryStrategySnapshot    strategies[TELEMETRY_STRATEGY_SLOTS];
    TelemetryPipelineSnapshot    pipeline;
    TelemetryTradeSnapshot       trade_ctx;
};

//+------------------------------------------------------------------+
//| T0 null-safe initializers (deterministic; no trading side-effects) |
//+------------------------------------------------------------------+
void Telemetry_MarketSnapshot_Init(TelemetryMarketSnapshot &o) {
    o.bar_time = 0;
    o.symbol = "";
    o.period_minutes = 0;
    o.atr14 = TELEMETRY_NULL_DOUBLE;
    o.adx = TELEMETRY_NULL_DOUBLE;
    o.bb_width = TELEMETRY_NULL_DOUBLE;
    o.ema_slope = TELEMETRY_NULL_DOUBLE;
    o.spread_points = TELEMETRY_NULL_DOUBLE;
    o.session_code = TELEMETRY_NULL_INT;
    o.hour_wit = TELEMETRY_NULL_INT;
    o.volatility_ratio = TELEMETRY_NULL_DOUBLE;
    o.efficiency_ratio = TELEMETRY_NULL_DOUBLE;
    o.false_breakout_count = TELEMETRY_NULL_INT;
    o.liquidity_proxy = TELEMETRY_NULL_DOUBLE;
}

void Telemetry_StrategySnapshot_Init(TelemetryStrategySnapshot &o) {
    o.signal_code = (int)SIGNAL_NONE;
    o.strength = 0.0;
    o.is_active = 0;
    o.adaptive_weight = TELEMETRY_NULL_DOUBLE;
    o.veto_reason_code = (int)SIGNAL_REJECT_NONE;
}

void Telemetry_PipelineSnapshot_Init(TelemetryPipelineSnapshot &o) {
    o.quality_score = TELEMETRY_NULL_DOUBLE;
    o.consensus_code = (int)SIGNAL_NONE;
    o.consensus_strength = TELEMETRY_NULL_DOUBLE;
    o.agreement_pct = TELEMETRY_NULL_DOUBLE;
    o.reject_reason_code = (int)SIGNAL_REJECT_NONE;
    o.risk_halt_flag = 0;
    o.cooldown_flag = 0;
}

void Telemetry_TradeSnapshot_Init(TelemetryTradeSnapshot &o) {
    o.regime_placeholder = TELEMETRY_NULL_INT;
    o.entry_context_placeholder = TELEMETRY_NULL_INT;
    o.hold_duration_sec_placeholder = TELEMETRY_NULL_INT;
    o.mae_placeholder = TELEMETRY_NULL_DOUBLE;
    o.mfe_placeholder = TELEMETRY_NULL_DOUBLE;
}

void Telemetry_BarRow_Init(TelemetryBarRow &row) {
    row.schema_id = TELEMETRY_SCHEMA_ID_ASCII;
    Telemetry_MarketSnapshot_Init(row.market);
    for(int i = 0; i < TELEMETRY_STRATEGY_SLOTS; i++)
        Telemetry_StrategySnapshot_Init(row.strategies[i]);
    Telemetry_PipelineSnapshot_Init(row.pipeline);
    Telemetry_TradeSnapshot_Init(row.trade_ctx);
}

#endif // __AURUM_TELEMETRY_TYPES_MQH__
