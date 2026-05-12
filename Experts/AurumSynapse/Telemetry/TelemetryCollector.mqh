//+------------------------------------------------------------------+
//|                                           TelemetryCollector.mqh |
//|                    Aurum Synapse — T1 passive read-only capture |
//| Include only when AURUM_TELEMETRY_T1 is defined (compile guard). |
//| No I/O, no CTrade, no engine mutation — field copies only.      |
//+------------------------------------------------------------------+
#ifndef __AURUM_TELEMETRY_COLLECTOR_MQH__
#define __AURUM_TELEMETRY_COLLECTOR_MQH__

#include "TelemetryTypes.mqh"
#include "TelemetryRingBuffer.mqh"
#include "../Core/Structures.mqh"

//+------------------------------------------------------------------+
//| Zero one bar row (T1 alias — same contract as TelemetryManager). |
//+------------------------------------------------------------------+
void TelemetryCollector_PrepareEmptyBarRow(TelemetryBarRow &row) {
    Telemetry_BarRow_Init(row);
}

//+------------------------------------------------------------------+
//| Read-only market fields → telemetry POD (no MarketState writes). |
//+------------------------------------------------------------------+
void TelemetryCollector_CollectReadOnlyMarketSnapshot(const MarketState &ms,
                                                      const datetime bar_time,
                                                      TelemetryMarketSnapshot &out) {
    out.bar_time = bar_time;
    out.symbol = _Symbol;
    const int ps = (int)PeriodSeconds(_Period);
    out.period_minutes = (ps > 0 ? ps / 60 : 0);
    out.atr14 = ms.atr14;
    out.adx = ms.adx;
    out.bb_width = ms.bbUpper - ms.bbLower;
    out.ema_slope = TELEMETRY_NULL_DOUBLE;
    out.spread_points = ms.spread;
    out.session_code = (int)ms.session;
    out.hour_wit = ms.hourWIT;
    out.volatility_ratio = ms.atrRatio;
    out.efficiency_ratio = TELEMETRY_NULL_DOUBLE;
    out.false_breakout_count = TELEMETRY_NULL_INT;
    out.liquidity_proxy = ms.volumeRatio;
}

//+------------------------------------------------------------------+
//| Read-only strategy slot (post-mask signals[] as observed in EA). |
//| Does not copy strategyName (avoids extra string churn per bar). |
//+------------------------------------------------------------------+
void TelemetryCollector_CollectReadOnlyStrategySnapshot(const SignalResult &sr,
                                                        TelemetryStrategySnapshot &out) {
    out.signal_code = (int)sr.signal;
    out.strength = sr.strength;
    out.is_active = (sr.isActive ? 1 : 0);
    out.adaptive_weight = sr.weight;
    out.veto_reason_code = (int)SIGNAL_REJECT_NONE;
}

//+------------------------------------------------------------------+
//| Pipeline edge snapshot — quality may be TELEMETRY_NULL_DOUBLE.    |
//+------------------------------------------------------------------+
void TelemetryCollector_FillPipelineReadOnly(const ENUM_SIGNAL consensus,
                                           const double consensusStrength,
                                           const double agreementPct,
                                           const double qualityScoreOrNull,
                                           const bool execRiskAllows,
                                           TelemetryPipelineSnapshot &out) {
    out.quality_score = qualityScoreOrNull;
    out.consensus_code = (int)consensus;
    out.consensus_strength = consensusStrength;
    out.agreement_pct = agreementPct;
    out.reject_reason_code = (int)SIGNAL_REJECT_NONE;
    out.risk_halt_flag = (execRiskAllows ? 0 : 1);
    out.cooldown_flag = 0;
}

//+------------------------------------------------------------------+
//| Build bar row (read-only) — ring / T2 enqueue use same snapshot. |
//+------------------------------------------------------------------+
void TelemetryCollector_BuildBarRow(const datetime bar_time,
                                    const MarketState &marketState,
                                    const SignalResult &signals[],
                                    const ENUM_SIGNAL consensus,
                                    const double consensusStrength,
                                    const double agreementPct,
                                    const double qualityScoreOrNull,
                                    const bool execRiskAllows,
                                    TelemetryBarRow &row) {
    TelemetryCollector_PrepareEmptyBarRow(row);
    TelemetryCollector_CollectReadOnlyMarketSnapshot(marketState, bar_time, row.market);
    const int n = TELEMETRY_STRATEGY_SLOTS;
    for(int i = 0; i < n; i++)
        TelemetryCollector_CollectReadOnlyStrategySnapshot(signals[i], row.strategies[i]);
    TelemetryCollector_FillPipelineReadOnly(consensus, consensusStrength, agreementPct,
                                            qualityScoreOrNull, execRiskAllows, row.pipeline);
    Telemetry_TradeSnapshot_Init(row.trade_ctx);
}

//+------------------------------------------------------------------+
//| T1 single call site: build row + push ring (memory only).         |
//+------------------------------------------------------------------+
void TelemetryCollector_OnBarPassive(const datetime bar_time,
                                     const MarketState &marketState,
                                     const SignalResult &signals[],
                                     const ENUM_SIGNAL consensus,
                                     const double consensusStrength,
                                     const double agreementPct,
                                     const double qualityScoreOrNull,
                                     const bool execRiskAllows) {
    TelemetryBarRow row;
    TelemetryCollector_BuildBarRow(bar_time, marketState, signals, consensus,
                                   consensusStrength, agreementPct, qualityScoreOrNull,
                                   execRiskAllows, row);
    TelemetryRingBuffer_PushCopy(row);
}

#endif // __AURUM_TELEMETRY_COLLECTOR_MQH__
