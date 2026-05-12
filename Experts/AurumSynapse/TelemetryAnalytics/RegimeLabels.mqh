//+------------------------------------------------------------------+
//|                                              RegimeLabels.mqh    |
//|     Derived REGIME_PROXY_* from bar features (CSV only).        |
//+------------------------------------------------------------------+
#ifndef __AURUM_REGIME_LABELS_MQH__
#define __AURUM_REGIME_LABELS_MQH__

#include "AnalyticsConfig.mqh"
#include "AnalyticsTypes.mqh"

//+------------------------------------------------------------------+
bool Analytics_IsNullDouble(const double v) {
    if(v != v)
        return true;
    if(v <= -1.0e99)
        return true;
    return false;
}

//+------------------------------------------------------------------+
//| Order: vol extremes first, then ADX trend/range, else neutral.   |
//+------------------------------------------------------------------+
ENUM_REGIME_PROXY RegimeProxy_Classify(const TelemetryCsvRow &r) {
    if(!r.null_vol) {
        if(r.volatility_ratio >= ANALYTICS_PROXY_VOL_HIGH)
            return REGIME_PROXY_HIGH_VOL;
        if(r.volatility_ratio <= ANALYTICS_PROXY_VOL_LOW)
            return REGIME_PROXY_LOW_VOL;
    }
    if(!r.null_adx) {
        if(r.adx >= ANALYTICS_PROXY_ADX_TREND)
            return REGIME_PROXY_TRENDING;
        if(r.adx <= ANALYTICS_PROXY_ADX_RANGE)
            return REGIME_PROXY_RANGING;
    }
    return REGIME_PROXY_NEUTRAL;
}

string RegimeProxy_Name(const ENUM_REGIME_PROXY rp) {
    switch(rp) {
        case REGIME_PROXY_HIGH_VOL:   return "HIGH_VOL";
        case REGIME_PROXY_LOW_VOL:    return "LOW_VOL";
        case REGIME_PROXY_TRENDING:   return "TRENDING";
        case REGIME_PROXY_RANGING:    return "RANGING";
        case REGIME_PROXY_NEUTRAL:    return "NEUTRAL";
        default:                      return "UNKNOWN";
    }
}

#endif // __AURUM_REGIME_LABELS_MQH__
