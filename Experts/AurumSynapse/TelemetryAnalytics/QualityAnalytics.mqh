//+------------------------------------------------------------------+
//|                                           QualityAnalytics.mqh   |
//|     Quality / consensus strength bins (CSV-native).           |
//+------------------------------------------------------------------+
#ifndef __AURUM_QUALITY_ANALYTICS_MQH__
#define __AURUM_QUALITY_ANALYTICS_MQH__

#include "AnalyticsTypes.mqh"

enum ENUM_QUALITY_BIN {
    QUALITY_BIN_NULL = 0,
    QUALITY_BIN_LOW,
    QUALITY_BIN_MID,
    QUALITY_BIN_HIGH,
    QUALITY_BIN_TOP,
    QUALITY_BIN_COUNT
};

struct QualityAnalyticsState {
    ulong        bars[QUALITY_BIN_COUNT];
    RunningStatD consensusStrength[QUALITY_BIN_COUNT];
    RunningStatD agreement[QUALITY_BIN_COUNT];
    ulong        riskHaltBars[QUALITY_BIN_COUNT];
};

ENUM_QUALITY_BIN QualityAnalytics_ClassifyBin(const TelemetryCsvRow &row) {
    if(row.null_quality)
        return QUALITY_BIN_NULL;
    if(row.quality < 50.0)
        return QUALITY_BIN_LOW;
    if(row.quality < 60.0)
        return QUALITY_BIN_MID;
    if(row.quality < 70.0)
        return QUALITY_BIN_HIGH;
    return QUALITY_BIN_TOP;
}

void QualityAnalytics_Reset(QualityAnalyticsState &s) {
    for(int i = 0; i < QUALITY_BIN_COUNT; i++) {
        s.bars[i] = 0;
        s.consensusStrength[i].Reset();
        s.agreement[i].Reset();
        s.riskHaltBars[i] = 0;
    }
}

void QualityAnalytics_Feed(QualityAnalyticsState &s, const TelemetryCsvRow &row) {
    const int k = (int)QualityAnalytics_ClassifyBin(row);
    s.bars[k]++;
    s.consensusStrength[k].Add(row.consensus_strength, row.null_consensus_strength);
    s.agreement[k].Add(row.agreement_pct, row.null_agreement);
    if(!row.null_risk_halt && row.risk_halt_flag != 0)
        s.riskHaltBars[k]++;
}

string QualityAnalytics_BinName(const int k) {
    switch(k) {
        case QUALITY_BIN_NULL: return "QUAL_NULL";
        case QUALITY_BIN_LOW:  return "QUAL_LT50";
        case QUALITY_BIN_MID:  return "QUAL_50_60";
        case QUALITY_BIN_HIGH: return "QUAL_60_70";
        case QUALITY_BIN_TOP:  return "QUAL_GE70";
        default: return "QUAL_OTHER";
    }
}

#endif // __AURUM_QUALITY_ANALYTICS_MQH__
