//+------------------------------------------------------------------+
//|                                              AnalyticsTypes.mqh  |
//|     Phase 3A — shared accumulators + parsed row (CSV-native)    |
//+------------------------------------------------------------------+
#ifndef __AURUM_ANALYTICS_TYPES_MQH__
#define __AURUM_ANALYTICS_TYPES_MQH__

#include "../Telemetry/TelemetryContracts.mqh"

//--- Proxy regime bucket (never feed into execution)
enum ENUM_REGIME_PROXY {
    REGIME_PROXY_UNKNOWN = 0,
    REGIME_PROXY_HIGH_VOL,
    REGIME_PROXY_LOW_VOL,
    REGIME_PROXY_TRENDING,
    REGIME_PROXY_RANGING,
    REGIME_PROXY_NEUTRAL,
    REGIME_PROXY_COUNT
};

//+------------------------------------------------------------------+
struct RunningStatD {
    ulong  n;
    double sum;
    void Reset(void) {
        n = 0;
        sum = 0.0;
    }
    void Add(const double v, const bool isNull) {
        if(isNull)
            return;
        n++;
        sum += v;
    }
    double Mean(void) const {
        return (n > 0 ? sum / (double)n : 0.0);
    }
};

//+------------------------------------------------------------------+
struct RunningStatI {
    ulong n;
    long  sum;
    void Reset(void) {
        n = 0;
        sum = 0;
    }
    void Add(const int v, const bool isNull) {
        if(isNull)
            return;
        n++;
        sum += (long)v;
    }
    double Mean(void) const {
        return (n > 0 ? (double)sum / (double)n : 0.0);
    }
};

//+------------------------------------------------------------------+
//| One telemetry CSV row (fields used by Phase 3A).                 |
//+------------------------------------------------------------------+
struct TelemetryCsvRow {
    bool   valid;
    double adx;
    double volatility_ratio;
    double bb_width;
    double spread_points;
    int    session_code;
    int    hour_wit;
    double quality;
    int    consensus_code;
    double consensus_strength;
    double agreement_pct;
    int    risk_halt_flag;
    bool   null_adx;
    bool   null_vol;
    bool   null_bb;
    bool   null_spread;
    bool   null_session;
    bool   null_hour;
    bool   null_quality;
    bool   null_consensus_strength;
    bool   null_agreement;
    int    strategy_signal[TELEMETRY_STRATEGY_SLOTS];
    double strategy_strength[TELEMETRY_STRATEGY_SLOTS];
    int    strategy_active[TELEMETRY_STRATEGY_SLOTS];
    bool   null_str_sig[TELEMETRY_STRATEGY_SLOTS];
    bool   null_str_strength[TELEMETRY_STRATEGY_SLOTS];
    bool   null_str_active[TELEMETRY_STRATEGY_SLOTS];
    bool   null_consensus;
    bool   null_risk_halt;
};

//--- Column indices — must match TelemetryWriter_CsvHeaderLine order (0-based)
#define TCOL_BAR_UTC             1
#define TCOL_SYMBOL              3
#define TCOL_PERIOD              4
#define TCOL_ATR14               5
#define TCOL_ADX                 6
#define TCOL_BB_WIDTH            7
#define TCOL_EMA_SLOPE           8
#define TCOL_SPREAD_PTS          9
#define TCOL_SESSION             10
#define TCOL_HOUR_WIT            11
#define TCOL_VOL_RATIO           12
#define TCOL_STR0_SIG            16
// str slot i: base = 16 + i*5  (sig,str,act,wgt,veto)
#define TCOL_STR_SIG(i)          (16 + (i) * 5)
#define TCOL_STR_STRENGTH(i)     (17 + (i) * 5)
#define TCOL_STR_ACTIVE(i)       (18 + (i) * 5)
#define TCOL_QUALITY             56
#define TCOL_CONSENSUS           57
#define TCOL_CONSENSUS_STRENGTH  58
#define TCOL_AGREEMENT_PCT       59
#define TCOL_RISK_HALT           61

#endif // __AURUM_ANALYTICS_TYPES_MQH__
