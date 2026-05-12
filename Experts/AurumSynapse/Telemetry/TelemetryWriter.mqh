//+------------------------------------------------------------------+
//|                                              TelemetryWriter.mqh |
//|                    T2 CSV line format (cold path only)           |
//+------------------------------------------------------------------+
#ifndef __AURUM_TELEMETRY_WRITER_MQH__
#define __AURUM_TELEMETRY_WRITER_MQH__

#include "TelemetryTypes.mqh"
#include "TelemetryContracts.mqh"

//+------------------------------------------------------------------+
//| Canonical header — must match TelemetrySchema.md                 |
//+------------------------------------------------------------------+
string TelemetryWriter_CsvHeaderLine(void) {
    return "schema,bar_utc,bar_time,symbol,period,atr14,adx,bb_width,ema_slope,spread_points,session_code,hour_wit,volatility_ratio,efficiency_ratio,false_breakout_cnt,liquidity_proxy,str0_sig,str0_str,str0_act,str0_wgt,str0_veto,str1_sig,str1_str,str1_act,str1_wgt,str1_veto,str2_sig,str2_str,str2_act,str2_wgt,str2_veto,str3_sig,str3_str,str3_act,str3_wgt,str3_veto,str4_sig,str4_str,str4_act,str4_wgt,str4_veto,str5_sig,str5_str,str5_act,str5_wgt,str5_veto,str6_sig,str6_str,str6_act,str6_wgt,str6_veto,str7_sig,str7_str,str7_act,str7_wgt,str7_veto,quality,consensus,consensus_strength,agreement_pct,reject_code,risk_halt,cooldown_flag,regime_ph,entry_ctx_ph,hold_sec_ph,mae_ph,mfe_ph";
}

string TelemetryWriter_Dstr(const double v) {
    return DoubleToString(v, 8);
}

string TelemetryWriter_Istr(const int v) {
    return IntegerToString(v);
}

//+------------------------------------------------------------------+
//| One CSV data line (no trailing newline — caller adds if needed). |
//+------------------------------------------------------------------+
void TelemetryWriter_FormatDataLine(const TelemetryBarRow &r, string &out) {
    out = r.schema_id;
    out += ",";
    out += IntegerToString((long)r.market.bar_time);
    out += ",";
    out += TimeToString(r.market.bar_time, TIME_DATE | TIME_MINUTES);
    out += ",";
    out += r.market.symbol;
    out += ",";
    out += IntegerToString(r.market.period_minutes);
    out += ",";
    out += TelemetryWriter_Dstr(r.market.atr14);
    out += ",";
    out += TelemetryWriter_Dstr(r.market.adx);
    out += ",";
    out += TelemetryWriter_Dstr(r.market.bb_width);
    out += ",";
    out += TelemetryWriter_Dstr(r.market.ema_slope);
    out += ",";
    out += TelemetryWriter_Dstr(r.market.spread_points);
    out += ",";
    out += TelemetryWriter_Istr(r.market.session_code);
    out += ",";
    out += TelemetryWriter_Istr(r.market.hour_wit);
    out += ",";
    out += TelemetryWriter_Dstr(r.market.volatility_ratio);
    out += ",";
    out += TelemetryWriter_Dstr(r.market.efficiency_ratio);
    out += ",";
    out += TelemetryWriter_Istr(r.market.false_breakout_count);
    out += ",";
    out += TelemetryWriter_Dstr(r.market.liquidity_proxy);
    for(int i = 0; i < TELEMETRY_STRATEGY_SLOTS; i++) {
        out += ",";
        out += TelemetryWriter_Istr(r.strategies[i].signal_code);
        out += ",";
        out += TelemetryWriter_Dstr(r.strategies[i].strength);
        out += ",";
        out += TelemetryWriter_Istr(r.strategies[i].is_active);
        out += ",";
        out += TelemetryWriter_Dstr(r.strategies[i].adaptive_weight);
        out += ",";
        out += TelemetryWriter_Istr(r.strategies[i].veto_reason_code);
    }
    out += ",";
    out += TelemetryWriter_Dstr(r.pipeline.quality_score);
    out += ",";
    out += TelemetryWriter_Istr(r.pipeline.consensus_code);
    out += ",";
    out += TelemetryWriter_Dstr(r.pipeline.consensus_strength);
    out += ",";
    out += TelemetryWriter_Dstr(r.pipeline.agreement_pct);
    out += ",";
    out += TelemetryWriter_Istr(r.pipeline.reject_reason_code);
    out += ",";
    out += TelemetryWriter_Istr(r.pipeline.risk_halt_flag);
    out += ",";
    out += TelemetryWriter_Istr(r.pipeline.cooldown_flag);
    out += ",";
    out += TelemetryWriter_Istr(r.trade_ctx.regime_placeholder);
    out += ",";
    out += TelemetryWriter_Istr(r.trade_ctx.entry_context_placeholder);
    out += ",";
    out += TelemetryWriter_Istr(r.trade_ctx.hold_duration_sec_placeholder);
    out += ",";
    out += TelemetryWriter_Dstr(r.trade_ctx.mae_placeholder);
    out += ",";
    out += TelemetryWriter_Dstr(r.trade_ctx.mfe_placeholder);
}

#endif // __AURUM_TELEMETRY_WRITER_MQH__
