//+------------------------------------------------------------------+
//|                                            RegimeAnalytics.mqh   |
//|     Per REGIME_PROXY_* descriptive stats (CSV-native).          |
//+------------------------------------------------------------------+
#ifndef __AURUM_REGIME_ANALYTICS_MQH__
#define __AURUM_REGIME_ANALYTICS_MQH__

#include "AnalyticsTypes.mqh"

struct RegimeAnalyticsState {
    ulong         bars[REGIME_PROXY_COUNT];
    RunningStatD  adx[REGIME_PROXY_COUNT];
    RunningStatD  volRatio[REGIME_PROXY_COUNT];
    RunningStatD  quality[REGIME_PROXY_COUNT];
    RunningStatD  agreement[REGIME_PROXY_COUNT];
    RunningStatD  spread[REGIME_PROXY_COUNT];
    ulong         riskHaltBars[REGIME_PROXY_COUNT];
};

void RegimeAnalytics_Reset(RegimeAnalyticsState &s) {
    for(int i = 0; i < REGIME_PROXY_COUNT; i++) {
        s.bars[i] = 0;
        s.adx[i].Reset();
        s.volRatio[i].Reset();
        s.quality[i].Reset();
        s.agreement[i].Reset();
        s.spread[i].Reset();
        s.riskHaltBars[i] = 0;
    }
}

void RegimeAnalytics_Feed(RegimeAnalyticsState &s, const TelemetryCsvRow &row, const ENUM_REGIME_PROXY rp) {
    const int k = (int)rp;
    if(k < 0 || k >= REGIME_PROXY_COUNT)
        return;
    s.bars[k]++;
    s.adx[k].Add(row.adx, row.null_adx);
    s.volRatio[k].Add(row.volatility_ratio, row.null_vol);
    s.quality[k].Add(row.quality, row.null_quality);
    s.agreement[k].Add(row.agreement_pct, row.null_agreement);
    s.spread[k].Add(row.spread_points, row.null_spread);
    if(!row.null_risk_halt && row.risk_halt_flag != 0)
        s.riskHaltBars[k]++;
}

#endif // __AURUM_REGIME_ANALYTICS_MQH__
